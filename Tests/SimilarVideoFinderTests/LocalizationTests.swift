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

final class LocalizationTests: XCTestCase {
    func testDefaultLanguageIsEnglishAndRawValuesRoundTrip() {
        XCTAssertEqual(AppLanguage.defaultLanguage, .english)
        XCTAssertEqual(AppLanguage(rawValue: "zh-Hans"), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.allCases.map(\.rawValue), ["en", "zh-Hans", "zh-Hant", "es", "fr"])
    }

    func testRepresentativeStringsSwitchLanguage() {
        XCTAssertEqual(L10n.chooseFolder(.english), "Choose Folder")
        XCTAssertEqual(L10n.chooseFolder(.simplifiedChinese), "选择文件夹")
        XCTAssertEqual(L10n.skippedFiles(3, .english), "Skipped 3 unreadable files")
        XCTAssertEqual(L10n.skippedFiles(3, .simplifiedChinese), "跳过 3 个无法读取的文件")
        XCTAssertEqual(L10n.similarMedia(.english), "Similar Media")
        XCTAssertEqual(L10n.similarMedia(.simplifiedChinese), "相似媒体")
        XCTAssertEqual(L10n.similarMedia(.traditionalChinese), "相似媒體")
        XCTAssertEqual(L10n.similarMedia(.spanish), "Medios similares")
        XCTAssertEqual(L10n.similarMedia(.french), "Médias similaires")
    }

    func testScanProgressDetailShowsCacheHitContext() {
        let fingerprint = ScanProgress(
            stage: .hashing,
            fraction: 1,
            currentFile: "",
            discoveredCount: 5,
            cacheHits: 3,
            cacheTotal: 5,
            cacheKind: .fingerprint
        )
        XCTAssertEqual(L10n.scanProgressDetail(fingerprint, .english), "Fingerprint cache hits: 3 of 5")
        XCTAssertEqual(L10n.scanProgressDetail(fingerprint, .simplifiedChinese), "指纹缓存命中：3 / 5")

        let metadata = ScanProgress(
            stage: .readingMetadata,
            fraction: 0.4,
            currentFile: "clip.mov",
            discoveredCount: 5,
            cacheHits: 2,
            cacheTotal: 5,
            cacheKind: .metadata
        )
        XCTAssertEqual(L10n.scanProgressDetail(metadata, .english), "Metadata cache hits: 2 of 5 - clip.mov")
    }
}
