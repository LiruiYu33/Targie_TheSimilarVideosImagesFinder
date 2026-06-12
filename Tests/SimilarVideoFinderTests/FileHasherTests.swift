import XCTest
@testable import SimilarVideoFinder

final class FileHasherTests: XCTestCase {
    func testIdenticalFilesHaveSameDigestAndChangedBytesDiffer() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("one.bin")
        let second = root.appendingPathComponent("two.bin")
        let third = root.appendingPathComponent("three.bin")
        try Data("same".utf8).write(to: first)
        try Data("same".utf8).write(to: second)
        try Data("different".utf8).write(to: third)

        let a = try await FileHasher.sha256(of: first)
        let b = try await FileHasher.sha256(of: second)
        let c = try await FileHasher.sha256(of: third)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
