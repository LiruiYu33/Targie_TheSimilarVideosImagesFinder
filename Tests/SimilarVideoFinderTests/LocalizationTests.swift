import XCTest
@testable import SimilarVideoFinder

final class LocalizationTests: XCTestCase {
    func testDefaultLanguageIsEnglishAndRawValuesRoundTrip() {
        XCTAssertEqual(AppLanguage.defaultLanguage, .english)
        XCTAssertEqual(AppLanguage(rawValue: "zh-Hans"), .simplifiedChinese)
    }

    func testRepresentativeStringsSwitchLanguage() {
        XCTAssertEqual(L10n.chooseFolder(.english), "Choose Folder")
        XCTAssertEqual(L10n.chooseFolder(.simplifiedChinese), "选择文件夹")
        XCTAssertEqual(L10n.skippedFiles(3, .english), "Skipped 3 unreadable files")
        XCTAssertEqual(L10n.skippedFiles(3, .simplifiedChinese), "跳过 3 个无法读取的文件")
    }
}
