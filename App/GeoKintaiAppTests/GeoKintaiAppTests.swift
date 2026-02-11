import XCTest
@testable import GeoKintaiApp

final class GeoKintaiAppTests: XCTestCase {
    @MainActor
    func testAppStore_initialLaunch_requiresWorkplaceSetup() {
        let store = AppStore()
        XCTAssertTrue(store.workplaces.isEmpty)
    }
}
