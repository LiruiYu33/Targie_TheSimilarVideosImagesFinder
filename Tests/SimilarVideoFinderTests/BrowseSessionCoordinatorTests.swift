// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import XCTest
@testable import SimilarVideoFinder

@MainActor
final class BrowseSessionCoordinatorTests: XCTestCase {
    func testPreparedBrowseModelIsReusedWhenEnteringBrowseMode() {
        let scanModel = ScanViewModel(hashCache: nil)
        scanModel.replaceResultsForTesting(
            items: [makeItem(name: "clip.mov")],
            relations: []
        )
        let coordinator = BrowseSessionCoordinator()

        coordinator.prepareIfPossible(scanModel: scanModel)
        let prepared = coordinator.browseModel
        let entered = coordinator.model(for: scanModel)

        XCTAssertNotNil(prepared)
        XCTAssertTrue(prepared === entered)
    }

    func testBrowseModelSurvivesLeavingBrowseMode() {
        let scanModel = ScanViewModel(hashCache: nil)
        scanModel.replaceResultsForTesting(
            items: [makeItem(name: "clip.mov")],
            relations: []
        )
        let coordinator = BrowseSessionCoordinator()
        let first = coordinator.model(for: scanModel)

        coordinator.leaveBrowseMode()
        let second = coordinator.model(for: scanModel)

        XCTAssertTrue(first === second)
    }

    private func makeItem(name: String) -> MediaItem {
        MediaItem(
            kind: .video,
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            fileSize: 100,
            duration: 1,
            width: 1920,
            height: 1080,
            modifiedAt: nil,
            thumbnailData: nil
        )
    }
}
