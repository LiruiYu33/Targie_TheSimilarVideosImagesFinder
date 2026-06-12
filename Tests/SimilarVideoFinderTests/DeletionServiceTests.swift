import XCTest
@testable import SimilarVideoFinder

final class DeletionServiceTests: XCTestCase {
    func testPermanentDeleteRemovesTemporaryFile() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("delete me".utf8).write(to: url)
        try await DeletionService().delete(url: url, mode: .permanent)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testMissingFileReturnsTypedError() async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try await DeletionService().delete(url: url, mode: .permanent)
            XCTFail("Expected missing file error")
        } catch let error as DeletionError {
            XCTAssertEqual(error, .fileMissing)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
