import XCTest
@testable import SimilarVideoFinder

final class FrameFeatureExtractorTests: XCTestCase {
    func testAggregationRequiresTwoSamplesAndIgnoresMissingValues() {
        XCTAssertNil(FrameSimilarityAggregator.aggregate([0.9, nil]))
        let result = FrameSimilarityAggregator.aggregate([0.9, nil, 0.7])
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0.8, accuracy: 0.0001)
    }
}
