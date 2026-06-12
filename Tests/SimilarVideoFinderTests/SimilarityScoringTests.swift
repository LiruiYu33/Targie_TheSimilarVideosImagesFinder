import XCTest
@testable import SimilarVideoFinder

final class SimilarityScoringTests: XCTestCase {
    func testStripsCopyAndExportNoise() {
        XCTAssertEqual(FilenameNormalizer.normalize("旅行 copy 2_export.mp4"), "旅行")
    }

    func testExactHashProducesCertainMatch() {
        let result = SimilarityScorer.score(
            Self.video(name: "one.mov"),
            Self.video(name: "two.mov"),
            hashesMatch: true,
            frameSimilarity: nil
        )
        XCTAssertEqual(result.score, 1.0)
        XCTAssertTrue(result.evidence.contains(.identicalContentHash))
    }

    func testMetadataAloneCannotClaimHighVisualMatch() {
        let result = SimilarityScorer.score(
            Self.video(name: "holiday.mov"),
            Self.video(name: "holiday copy.mov"),
            hashesMatch: false,
            frameSimilarity: nil
        )
        XCTAssertLessThan(result.score, 0.82)
    }

    static func video(name: String, size: Int64 = 1_000_000, duration: Double = 60) -> VideoItem {
        VideoItem(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            fileSize: size,
            duration: duration,
            width: 1920,
            height: 1080,
            modifiedAt: nil,
            thumbnailData: nil
        )
    }
}
