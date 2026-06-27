// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import XCTest
@testable import SimilarVideoFinder

final class BrowseRowSelectionIntentTests: XCTestCase {
    func testPlainClickReplacesSelection() {
        XCTAssertEqual(BrowseRowSelectionIntent.make(isCommandPressed: false, isShiftPressed: false), .replace)
    }

    func testCommandClickTogglesSelection() {
        XCTAssertEqual(BrowseRowSelectionIntent.make(isCommandPressed: true, isShiftPressed: false), .toggle)
    }

    func testShiftClickExtendsSelectionEvenWhenCommandIsAlsoPressed() {
        XCTAssertEqual(BrowseRowSelectionIntent.make(isCommandPressed: true, isShiftPressed: true), .extend)
    }
}
