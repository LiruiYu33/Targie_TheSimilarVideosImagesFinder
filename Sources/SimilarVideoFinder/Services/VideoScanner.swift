import AppKit
import AVFoundation
import Foundation

struct VideoScanResult: Sendable {
    let videos: [VideoItem]
    let issues: [ScanIssue]
}

struct VideoScanner {
    static let supportedExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv", "webm", "mpeg", "mpg", "3gp"
    ]

    static func discoverVideoURLs(in folder: URL) throws -> [URL] {
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
                  Self.supportedExtensions.contains(url.pathExtension.lowercased()) else { return nil }
            return url
        }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func scan(
        folder: URL,
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async throws -> VideoScanResult {
        let urls = try Self.discoverVideoURLs(in: folder)
        await progress(ScanProgress(stage: .readingMetadata, fraction: 0, discoveredCount: urls.count))
        var videos: [VideoItem] = []
        var issues: [ScanIssue] = []
        for (index, url) in urls.enumerated() {
            try Task.checkCancellation()
            do {
                videos.append(try await loadVideo(at: url))
            } catch ScannerError.noVideoTrack {
                issues.append(ScanIssue(url: url, reason: .noVideoTrack))
            } catch {
                issues.append(ScanIssue(url: url, reason: .message(error.localizedDescription)))
            }
            await progress(ScanProgress(
                stage: .readingMetadata,
                fraction: urls.isEmpty ? 1 : Double(index + 1) / Double(urls.count),
                currentFile: url.lastPathComponent,
                discoveredCount: urls.count
            ))
        }
        return VideoScanResult(videos: videos, issues: issues)
    }

    private func loadVideo(at url: URL) async throws -> VideoItem {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else { throw ScannerError.noVideoTrack }
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let transformed = naturalSize.applying(transform)
        let width = Int(abs(transformed.width).rounded())
        let height = Int(abs(transformed.height).rounded())
        let thumbnail = await thumbnailData(asset: asset, duration: duration)
        return VideoItem(
            url: url,
            fileSize: Int64(values.fileSize ?? 0),
            duration: duration,
            width: width,
            height: height,
            modifiedAt: values.contentModificationDate,
            thumbnailData: thumbnail
        )
    }

    private func thumbnailData(asset: AVAsset, duration: Double) async -> Data? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 405)
        let time = CMTime(seconds: max(0, duration * 0.35), preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        let representation = NSBitmapImageRep(cgImage: cgImage)
        return representation.representation(using: .jpeg, properties: [.compressionFactor: 0.78])
    }
}

enum ScannerError: Error {
    case noVideoTrack
}
