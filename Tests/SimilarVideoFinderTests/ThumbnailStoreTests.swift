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

    func testPruneStaleRemovesThumbnailsOutsideValidSourceSet() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ThumbnailStorePruneTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ThumbnailStore(directoryURL: root)
        let date = Date(timeIntervalSince1970: 456)
        let keepSource = URL(fileURLWithPath: "/media/keep.jpg")
        let staleSource = URL(fileURLWithPath: "/media/stale.jpg")
        let keepThumbnail = try store.persist(Data([1]), sourceURL: keepSource, modifiedAt: date)
        let staleThumbnail = try store.persist(Data([2]), sourceURL: staleSource, modifiedAt: date)

        try store.pruneStale(validSourceURLs: [keepSource])

        XCTAssertTrue(FileManager.default.fileExists(atPath: keepThumbnail.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleThumbnail.path))
        XCTAssertEqual(store.count(), 1)
    }
}
