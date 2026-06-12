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
