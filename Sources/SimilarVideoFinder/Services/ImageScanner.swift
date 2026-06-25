// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import AppKit
import Foundation
import ImageIO

struct ImageScanResult: Sendable {
    let images: [MediaItem]
    let issues: [ScanIssue]
}

struct ImageScanner: Sendable {
    typealias ImageLoader = @Sendable (URL) async throws -> MediaItem

    static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "webp", "tif", "tiff", "gif", "bmp"
    ]

    let maxConcurrentLoads: Int
    let loader: ImageLoader
    let metadataCache: (any HashCaching)?

    init(
        maxConcurrentLoads: Int = min(4, max(2, ProcessInfo.processInfo.activeProcessorCount / 2)),
        thumbnailStore: ThumbnailStore = .shared,
        metadataCache: (any HashCaching)? = nil,
        loader: ImageLoader? = nil
    ) {
        self.maxConcurrentLoads = max(1, maxConcurrentLoads)
        self.metadataCache = metadataCache
        self.loader = loader ?? { url in try await Self.loadImage(at: url, thumbnailStore: thumbnailStore, metadataCache: metadataCache) }
    }

    static func discoverImageURLs(in folder: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        return enumerator.compactMap { element -> URL? in
            guard let url = element as? URL,
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                  supportedExtensions.contains(url.pathExtension.lowercased()) else { return nil }
            return url
        }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func scan(
        folder: URL,
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async throws -> ImageScanResult {
        let urls = try Self.discoverImageURLs(in: folder)
        await progress(ScanProgress(stage: .readingMetadata, fraction: 0, discoveredCount: urls.count))

        let loader = self.loader
        let limit = maxConcurrentLoads
        let results = try await withThrowingTaskGroup(of: LoadedImage.self) { group in
            var iterator = Array(urls.enumerated()).makeIterator()
            var collected: [LoadedImage] = []
            var completed = 0

            for _ in 0..<min(limit, urls.count) {
                guard let next = iterator.next() else { break }
                group.addTask { try await Self.load(index: next.offset, url: next.element, using: loader) }
            }

            while let result = try await group.next() {
                try Task.checkCancellation()
                collected.append(result)
                completed += 1
                await progress(ScanProgress(
                    stage: .readingMetadata,
                    fraction: urls.isEmpty ? 1 : Double(completed) / Double(urls.count),
                    currentFile: result.url.lastPathComponent,
                    discoveredCount: urls.count
                ))
                if let next = iterator.next() {
                    group.addTask { try await Self.load(index: next.offset, url: next.element, using: loader) }
                }
            }
            return collected.sorted { $0.index < $1.index }
        }

        return ImageScanResult(
            images: results.compactMap(\.image),
            issues: results.compactMap(\.issue)
        )
    }

    private static func load(index: Int, url: URL, using loader: ImageLoader) async throws -> LoadedImage {
        do {
            return LoadedImage(index: index, url: url, image: try await loader(url), issue: nil)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return LoadedImage(
                index: index,
                url: url,
                image: nil,
                issue: ScanIssue(url: url, reason: .unreadableImage)
            )
        }
    }

    private static func loadImage(at url: URL, thumbnailStore: ThumbnailStore, metadataCache: (any HashCaching)?) async throws -> MediaItem {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [
            kCGImageSourceShouldCache: false
        ] as CFDictionary),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let rawWidth = properties[kCGImagePropertyPixelWidth] as? NSNumber,
        let rawHeight = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            throw ImageScannerError.unreadableImage
        }

        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        let swapsDimensions = [5, 6, 7, 8].contains(orientation)
        let width = swapsDimensions ? rawHeight.intValue : rawWidth.intValue
        let height = swapsDimensions ? rawWidth.intValue : rawHeight.intValue

        // Store minimal metadata so `detectMove` can locate the old path when
        // this image is later moved to a different folder.
        if let cache = metadataCache {
            await cache.upsertMetadata(
                filePath: url.path,
                fileSize: Int64(values.fileSize ?? 0),
                modifiedAt: values.contentModificationDate,
                mediaKind: .image,
                duration: nil,
                width: width,
                height: height
            )
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 720,
            kCGImageSourceShouldCacheImmediately: true
        ]
        // Reuse a persisted thumbnail if one exists for this (path, modifiedAt)
        // — avoids re-decoding and re-downscaling the image on re-scan.
        if let existingURL = thumbnailStore.existingThumbnailURL(for: url, modifiedAt: values.contentModificationDate) {
            return MediaItem(
                kind: .image,
                url: url,
                fileSize: Int64(values.fileSize ?? 0),
                duration: nil,
                width: width,
                height: height,
                modifiedAt: values.contentModificationDate,
                thumbnailData: nil,
                thumbnailURL: existingURL
            )
        }
        // Move detection: the file may have been relocated from another folder.
        // Ask HashCache for the old path and migrate the thumbnail precisely
        // (avoids the race condition of a fuzzy modifiedAt scan).
        let migratedURL: URL?
        if let cache = metadataCache,
           let oldPath = await cache.detectMove(
               filePath: url.path,
               fileSize: Int64(values.fileSize ?? 0),
               modifiedAt: values.contentModificationDate,
               mediaKind: .image,
               algorithmVersion: ImageSimilarityPipeline.algorithmVersion
           ) {
            migratedURL = thumbnailStore.migrateFromOldPath(oldPath, to: url, modifiedAt: values.contentModificationDate)
        } else {
            migratedURL = nil
        }
        if let migratedURL {
            return MediaItem(
                kind: .image,
                url: url,
                fileSize: Int64(values.fileSize ?? 0),
                duration: nil,
                width: width,
                height: height,
                modifiedAt: values.contentModificationDate,
                thumbnailData: nil,
                thumbnailURL: migratedURL
            )
        }
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw ImageScannerError.unreadableImage
        }
        let representation = NSBitmapImageRep(cgImage: thumbnail)
        let thumbnailData = representation.representation(using: .jpeg, properties: [.compressionFactor: 0.78])
        let thumbnailURL = thumbnailData.flatMap {
            try? thumbnailStore.persist($0, sourceURL: url, modifiedAt: values.contentModificationDate)
        }

        return MediaItem(
            kind: .image,
            url: url,
            fileSize: Int64(values.fileSize ?? 0),
            duration: nil,
            width: width,
            height: height,
            modifiedAt: values.contentModificationDate,
            thumbnailData: thumbnailURL == nil ? thumbnailData : nil,
            thumbnailURL: thumbnailURL
        )
    }
}

private struct LoadedImage: Sendable {
    let index: Int
    let url: URL
    let image: MediaItem?
    let issue: ScanIssue?
}

private enum ImageScannerError: Error {
    case unreadableImage
}
