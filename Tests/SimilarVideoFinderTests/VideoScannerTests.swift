import XCTest
@testable import SimilarVideoFinder

final class VideoScannerTests: XCTestCase {
    func testDiscoversSupportedVideosRecursivelyInStableOrder() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nested = root.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        for path in ["b.mov", "nested/a.mp4", "nested/c.M4V", "notes.txt"] {
            let url = root.appendingPathComponent(path)
            try Data("fixture".utf8).write(to: url)
        }

        let found = try VideoScanner.discoverVideoURLs(in: root)
        XCTAssertEqual(found.map(\.lastPathComponent), ["b.mov", "a.mp4", "c.M4V"])
    }
}
