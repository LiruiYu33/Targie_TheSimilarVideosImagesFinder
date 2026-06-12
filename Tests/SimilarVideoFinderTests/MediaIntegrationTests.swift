import XCTest
@testable import SimilarVideoFinder

final class MediaIntegrationTests: XCTestCase {
    func testRealVideoScanAndExactDuplicateGrouping() async throws {
        let ffmpeg = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        guard FileManager.default.isExecutableFile(atPath: ffmpeg.path) else {
            throw XCTSkip("ffmpeg is unavailable")
        }

        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("sample.mp4")
        let duplicate = root.appendingPathComponent("sample copy.mp4")

        let process = Process()
        process.executableURL = ffmpeg
        process.arguments = [
            "-loglevel", "error", "-f", "lavfi", "-i", "testsrc=size=320x180:rate=12",
            "-t", "1", "-pix_fmt", "yuv420p", "-y", original.path
        ]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        try FileManager.default.copyItem(at: original, to: duplicate)

        let scan = try await VideoScanner().scan(folder: root) { _ in }
        XCTAssertEqual(scan.videos.count, 2)
        XCTAssertTrue(scan.issues.isEmpty)

        let result = try await SimilarityPipeline().process(videos: scan.videos, threshold: 0.88) { _ in }
        XCTAssertEqual(result.groups.count, 1)
        XCTAssertEqual(result.groups[0].videos.count, 2)
        XCTAssertEqual(result.groups[0].maximumScore, 1)
    }
}
