import XCTest
@testable import SimilarVideoFinder

final class SimilarityGrouperTests: XCTestCase {
    func testChainRelationsFormOneGroup() {
        let a = SimilarityScoringTests.video(name: "a.mov")
        let b = SimilarityScoringTests.video(name: "b.mov")
        let c = SimilarityScoringTests.video(name: "c.mov")
        let groups = SimilarityGrouper.groups(
            items: [a, b, c],
            relations: [
                SimilarityRelation(firstID: a.id, secondID: b.id, score: 0.94, evidence: []),
                SimilarityRelation(firstID: b.id, secondID: c.id, score: 0.91, evidence: [])
            ],
            threshold: 0.90
        )

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].videos.map(\.id)), Set([a.id, b.id, c.id]))
    }

    func testRemovingVideoDropsSingletonGroup() {
        let a = SimilarityScoringTests.video(name: "a.mov")
        XCTAssertTrue(SimilarityGrouper.groups(items: [a], relations: [], threshold: 0.90).isEmpty)
    }
}
