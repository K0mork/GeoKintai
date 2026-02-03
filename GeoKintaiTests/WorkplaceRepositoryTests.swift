import XCTest
@testable import GeoKintai

@MainActor
final class WorkplaceRepositoryTests: XCTestCase {
    func testAddFetchDeleteWorkplace() throws {
        let controller = PersistenceController(inMemory: true)
        let repository = WorkplaceRepository(context: controller.viewContext)
        let createdAt = Date(timeIntervalSince1970: 0)

        let workplace = try repository.add(
            name: "HQ",
            latitude: 35.0,
            longitude: 139.0,
            radius: 150.0,
            monitoringEnabled: false,
            createdAt: createdAt
        )

        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 1)
        let fetched = all[0]
        XCTAssertEqual(fetched.id, workplace.id)
        XCTAssertEqual(fetched.name, "HQ")
        XCTAssertEqual(fetched.kLatitude, 35.0)
        XCTAssertEqual(fetched.kLongitude, 139.0)
        XCTAssertEqual(fetched.radius, 150.0)
        XCTAssertEqual(fetched.monitoringEnabled, false)
        XCTAssertEqual(fetched.createdAt, createdAt)

        try repository.delete(fetched)
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }
}
