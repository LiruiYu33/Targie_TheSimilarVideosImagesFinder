// Targie — Find similar videos on macOS.
// Copyright (C) 2026 Lirui Yu
//
// This file is part of Targie.
//
// Targie is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Targie is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Targie.  If not, see <https://www.gnu.org/licenses/>.
//
// If you reuse this code (modified or not), you must keep this notice
// and credit the original author (Lirui Yu).

import XCTest
@testable import SimilarVideoFinder

@MainActor
final class ScanViewModelTests: XCTestCase {
    func testDeletePromptStartsByChoosingMethod() {
        let model = ScanViewModel()
        model.requestDeletion(of: SimilarityScoringTests.video(name: "a.mov"))
        XCTAssertEqual(model.deletePrompt?.step, .choosingMethod)
    }

    func testSuccessfulDeletionDropsSingletonGroup() async {
        let a = SimilarityScoringTests.video(name: "a.mov")
        let b = SimilarityScoringTests.video(name: "b.mov")
        let relation = SimilarityRelation(firstID: a.id, secondID: b.id, score: 0.95, evidence: [.similarFrames])
        let deletion = FakeDeletionService()
        let model = ScanViewModel(deletionService: deletion)
        model.replaceResultsForTesting(videos: [a, b], relations: [relation])

        await model.confirmDeletion(of: b, mode: .permanent)

        XCTAssertTrue(model.groups.isEmpty)
        XCTAssertEqual(deletion.deletedURLs, [b.url])
    }
}

@MainActor
private final class FakeDeletionService: DeletionServicing {
    var deletedURLs: [URL] = []

    func delete(url: URL, mode: DeletionMode) async throws {
        deletedURLs.append(url)
    }

    func reveal(_ url: URL) {}
    func open(_ url: URL) {}
}
