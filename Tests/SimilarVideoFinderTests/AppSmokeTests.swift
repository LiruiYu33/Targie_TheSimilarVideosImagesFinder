import XCTest
@testable import SimilarVideoFinder

final class AppSmokeTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertEqual(AppIdentity.displayName, "Targie")
    }

    @MainActor
    func testAppCanInitializeBeforeApplicationLifecycleStarts() {
        _ = SimilarVideoFinderApp()
    }
}
