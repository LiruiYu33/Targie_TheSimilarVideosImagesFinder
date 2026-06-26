// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import SimilarVideoFinder

final class ImageSimilarityPipelineTests: XCTestCase {
    func testExactDuplicateImagesFormAGroup() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ImagePipeline-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("first.png")
        let second = root.appendingPathComponent("second.png")
        try writePattern(to: first)
        try FileManager.default.copyItem(at: first, to: second)
        let scan = try await ImageScanner().scan(folder: root) { _ in }

        let result = try await ImageSimilarityPipeline(cache: InMemoryHashCache()).process(images: scan.images, threshold: 0.88) { _ in }

        XCTAssertEqual(result.groups.count, 1)
        XCTAssertEqual(result.groups[0].items.count, 2)
        XCTAssertEqual(result.groups[0].kind, .image)
    }

    func testCachedImageHashesAdvanceHashingProgress() async throws {
        let image = MediaItem(
            kind: .image,
            url: URL(fileURLWithPath: "/tmp/cached-image.jpg"),
            fileSize: 10,
            duration: nil,
            width: 40,
            height: 20,
            modifiedAt: nil,
            thumbnailData: nil
        )
        let cache = InMemoryHashCache()
        var record = CacheRecord(
            filePath: image.url.path,
            fileSize: image.fileSize,
            modifiedAt: image.modifiedAt,
            perceptualHash: Data([0, 1, 2, 3, 4, 5, 6, 7]),
            prehashDurationBucket: 0,
            prehashSizeBucket: 0,
            prehashAspectBucket: 0,
            prehashThumbnailMean: 0,
            prehashThumbnailVariance: 0
        )
        record.mediaKind = MediaKind.image.rawValue
        record.algorithmVersion = ImageSimilarityPipeline.algorithmVersion
        await cache.upsert(record)
        let progress = ImageProgressRecorder()

        _ = try await ImageSimilarityPipeline(cache: cache).process(images: [image], threshold: 0.88) {
            await progress.append($0)
        }

        let hashingFractions = await progress.fractions(for: .hashing)
        XCTAssertTrue(hashingFractions.contains(1))
        let hashingUpdates = await progress.updates(for: .hashing)
        let finalHashing = try XCTUnwrap(hashingUpdates.last)
        XCTAssertEqual(finalHashing.cacheKind, .fingerprint)
        XCTAssertEqual(finalHashing.cacheHits, 1)
        XCTAssertEqual(finalHashing.cacheTotal, 1)
    }

    private func writePattern(to url: URL) throws {
        guard let context = CGContext(data: nil, width: 80, height: 60, bitsPerComponent: 8, bytesPerRow: 320, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw CocoaError(.fileWriteUnknown) }
        context.setFillColor(CGColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 60))
        context.setFillColor(CGColor.white)
        context.fillEllipse(in: CGRect(x: 15, y: 10, width: 35, height: 35))
        guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}

private actor ImageProgressRecorder {
    private var updates: [ScanProgress] = []

    func append(_ update: ScanProgress) {
        updates.append(update)
    }

    func fractions(for stage: ScanStage) -> [Double] {
        updates.filter { $0.stage == stage }.map(\.fraction)
    }

    func updates(for stage: ScanStage) -> [ScanProgress] {
        updates.filter { $0.stage == stage }
    }
}
