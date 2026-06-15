// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import Foundation
import XCTest
@testable import SimilarVideoFinder

final class ThumbnailStoreTests: XCTestCase {
    func testDiskBackedThumbnailLoadsThroughMediaItem() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ThumbnailStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ThumbnailStore(directoryURL: root)
        let data = Data([1, 2, 3, 4])
        let thumbnailURL = try store.persist(
            data,
            sourceURL: URL(fileURLWithPath: "/media/example.jpg"),
            modifiedAt: Date(timeIntervalSince1970: 123)
        )

        let item = MediaItem(
            kind: .image,
            url: URL(fileURLWithPath: "/media/example.jpg"),
            fileSize: 4,
            duration: nil,
            width: 1,
            height: 1,
            modifiedAt: Date(timeIntervalSince1970: 123),
            thumbnailData: nil,
            thumbnailURL: thumbnailURL
        )

        XCTAssertTrue(item.isThumbnailDiskBacked)
        XCTAssertEqual(item.thumbnailData, data)
    }
}
