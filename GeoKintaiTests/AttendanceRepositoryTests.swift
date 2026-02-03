import XCTest
@testable import GeoKintai

@MainActor
final class AttendanceRepositoryTests: XCTestCase {
    func testCheckInAndCheckOut() throws {
        let controller = PersistenceController(inMemory: true)
        let repository = AttendanceRepository(context: controller.viewContext)
        let workplaceId = UUID()
        let entryTime = Date(timeIntervalSince1970: 100)
        let exitTime = Date(timeIntervalSince1970: 200)

        let record = try repository.checkIn(
            workplaceId: workplaceId,
            entryTime: entryTime,
            isManual: false,
            note: "auto"
        )

        XCTAssertEqual(record.entryTime, entryTime)
        XCTAssertNil(record.exitTime)
        XCTAssertEqual(record.isManual, false)
        XCTAssertEqual(record.note, "auto")

        var records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].id, record.id)

        try repository.checkOut(record, exitTime: exitTime)
        records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records[0].exitTime, exitTime)
    }
}
