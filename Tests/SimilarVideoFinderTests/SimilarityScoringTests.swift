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
