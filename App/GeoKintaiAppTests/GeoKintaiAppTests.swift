import XCTest
@testable import GeoKintaiApp

final class GeoKintaiAppTests: XCTestCase {
    @MainActor
    func testAppStore_bootstrapCreatesDefaultWorkplace() {
        let store = AppStore()
        XCTAssertFalse(store.workplaces.isEmpty)
    }
}
