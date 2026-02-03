import XCTest
@testable import GeoKintai

@MainActor
final class WorkplaceRepositoryTests: XCTestCase {
    var controller: PersistenceController!
    var repository: WorkplaceRepository!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        repository = WorkplaceRepository(context: controller.viewContext)
    }

    // MARK: - Add Tests

    func testAddWorkplaceWithDefaultValues() throws {
        let workplace = try repository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )

        XCTAssertEqual(workplace.name, "Office")
        XCTAssertEqual(workplace.radius, 100.0) // Default
        XCTAssertEqual(workplace.monitoringEnabled, true) // Default
        XCTAssertNotNil(workplace.id)
    }

    func testAddWorkplaceWithCustomValues() throws {
        let createdAt = Date(timeIntervalSince1970: 0)
        let workplace = try repository.add(
            name: "HQ",
            latitude: 35.0,
            longitude: 139.0,
            radius: 150.0,
            monitoringEnabled: false,
            createdAt: createdAt
        )

        XCTAssertEqual(workplace.name, "HQ")
        XCTAssertEqual(workplace.kLatitude, 35.0)
        XCTAssertEqual(workplace.kLongitude, 139.0)
        XCTAssertEqual(workplace.radius, 150.0)
        XCTAssertEqual(workplace.monitoringEnabled, false)
        XCTAssertEqual(workplace.createdAt, createdAt)
    }

    func testAddMultipleWorkplaces() throws {
        try repository.add(name: "Office A", latitude: 35.0, longitude: 139.0)
        try repository.add(name: "Office B", latitude: 36.0, longitude: 140.0)
        try repository.add(name: "Office C", latitude: 37.0, longitude: 141.0)

        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 3)
    }

    // MARK: - Fetch Tests

    func testFetchAllReturnsEmptyArrayWhenNoWorkplaces() throws {
        let all = try repository.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testFetchAllReturnsSortedByCreatedAt() throws {
        let date1 = Date(timeIntervalSince1970: 100)
        let date2 = Date(timeIntervalSince1970: 200)
        let date3 = Date(timeIntervalSince1970: 50)

        try repository.add(name: "Second", latitude: 35.0, longitude: 139.0, createdAt: date1)
        try repository.add(name: "Third", latitude: 36.0, longitude: 140.0, createdAt: date2)
        try repository.add(name: "First", latitude: 37.0, longitude: 141.0, createdAt: date3)

        let all = try repository.fetchAll()
        XCTAssertEqual(all[0].name, "First")
        XCTAssertEqual(all[1].name, "Second")
        XCTAssertEqual(all[2].name, "Third")
    }

    // MARK: - Delete Tests

    func testDeleteWorkplace() throws {
        let workplace = try repository.add(name: "ToDelete", latitude: 35.0, longitude: 139.0)
        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(workplace)
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }

    func testDeleteOneOfMultipleWorkplaces() throws {
        let wp1 = try repository.add(name: "Keep", latitude: 35.0, longitude: 139.0)
        let wp2 = try repository.add(name: "Delete", latitude: 36.0, longitude: 140.0)

        try repository.delete(wp2)

        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].id, wp1.id)
    }

    // MARK: - Edge Cases

    func testAddWorkplaceWithEmptyName() throws {
        let workplace = try repository.add(name: "", latitude: 35.0, longitude: 139.0)
        XCTAssertEqual(workplace.name, "")
    }

    func testAddWorkplaceWithExtremeCoordinates() throws {
        let workplace = try repository.add(name: "Pole", latitude: 90.0, longitude: 180.0)
        XCTAssertEqual(workplace.kLatitude, 90.0)
        XCTAssertEqual(workplace.kLongitude, 180.0)
    }

    func testAddWorkplaceWithNegativeCoordinates() throws {
        let workplace = try repository.add(name: "South", latitude: -35.0, longitude: -139.0)
        XCTAssertEqual(workplace.kLatitude, -35.0)
        XCTAssertEqual(workplace.kLongitude, -139.0)
    }

    func testAddWorkplaceWithSmallRadius() throws {
        let workplace = try repository.add(name: "Small", latitude: 35.0, longitude: 139.0, radius: 10.0)
        XCTAssertEqual(workplace.radius, 10.0)
    }

    func testAddWorkplaceWithLargeRadius() throws {
        let workplace = try repository.add(name: "Large", latitude: 35.0, longitude: 139.0, radius: 1000.0)
        XCTAssertEqual(workplace.radius, 1000.0)
    }
}
