import XCTest
import CoreData
@testable import GeoKintai

final class PersistenceControllerTests: XCTestCase {
    func testPersistentContainerLoads() async {
        let controller = await PersistenceController(inMemory: true)
        let container = await controller.container
        XCTAssertNotNil(container)
        let description = container.persistentStoreDescriptions.first
        XCTAssertNotNil(description)
        XCTAssertEqual(description?.type, NSInMemoryStoreType)
        XCTAssertEqual(description?.url?.path, "/dev/null")
    }
}
