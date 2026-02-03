import XCTest
@testable import GeoKintai

@MainActor
final class AttendanceRepositoryTests: XCTestCase {
    var controller: PersistenceController!
    var repository: AttendanceRepository!
    var workplaceId: UUID!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        repository = AttendanceRepository(context: controller.viewContext)
        workplaceId = UUID()
    }

    // MARK: - Check In Tests

    func testCheckInCreatesRecord() throws {
        let record = try repository.checkIn(workplaceId: workplaceId)

        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.workplaceId, workplaceId)
        XCTAssertNil(record.exitTime)
        XCTAssertFalse(record.isManual)
        XCTAssertNil(record.note)
    }

    func testCheckInWithCustomValues() throws {
        let entryTime = Date(timeIntervalSince1970: 100)
        let record = try repository.checkIn(
            workplaceId: workplaceId,
            entryTime: entryTime,
            isManual: true,
            note: "Manual entry"
        )

        XCTAssertEqual(record.entryTime, entryTime)
        XCTAssertTrue(record.isManual)
        XCTAssertEqual(record.note, "Manual entry")
    }

    func testCheckInMultipleTimes() throws {
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 100))
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 200))
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 300))

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 3)
    }

    // MARK: - Check Out Tests

    func testCheckOut() throws {
        let record = try repository.checkIn(workplaceId: workplaceId)
        XCTAssertNil(record.exitTime)

        let exitTime = Date(timeIntervalSince1970: 200)
        try repository.checkOut(record, exitTime: exitTime)

        XCTAssertEqual(record.exitTime, exitTime)
    }

    func testCheckOutWithDefaultTime() throws {
        let record = try repository.checkIn(workplaceId: workplaceId)
        let beforeCheckOut = Date()

        try repository.checkOut(record)

        XCTAssertNotNil(record.exitTime)
        XCTAssertGreaterThanOrEqual(record.exitTime!, beforeCheckOut)
    }

    // MARK: - Fetch Tests

    func testFetchRecordsReturnsEmptyForNewWorkplace() throws {
        let records = try repository.fetchRecords(for: UUID())
        XCTAssertTrue(records.isEmpty)
    }

    func testFetchRecordsReturnsSortedByEntryTime() throws {
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 300))
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 100))
        try repository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 200))

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records[0].entryTime, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(records[1].entryTime, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(records[2].entryTime, Date(timeIntervalSince1970: 300))
    }

    func testFetchRecordsFiltersByWorkplace() throws {
        let workplace1 = UUID()
        let workplace2 = UUID()

        try repository.checkIn(workplaceId: workplace1)
        try repository.checkIn(workplaceId: workplace1)
        try repository.checkIn(workplaceId: workplace2)

        let records1 = try repository.fetchRecords(for: workplace1)
        let records2 = try repository.fetchRecords(for: workplace2)

        XCTAssertEqual(records1.count, 2)
        XCTAssertEqual(records2.count, 1)
    }

    // MARK: - Edge Cases

    func testCheckInWithEmptyNote() throws {
        let record = try repository.checkIn(workplaceId: workplaceId, note: "")
        XCTAssertEqual(record.note, "")
    }

    func testCheckInWithLongNote() throws {
        let longNote = String(repeating: "a", count: 1000)
        let record = try repository.checkIn(workplaceId: workplaceId, note: longNote)
        XCTAssertEqual(record.note, longNote)
    }

    func testFullWorkflow() throws {
        // Day 1: Check in and out
        let entry1 = Date(timeIntervalSince1970: 1000)
        let exit1 = Date(timeIntervalSince1970: 2000)
        let record1 = try repository.checkIn(workplaceId: workplaceId, entryTime: entry1)
        try repository.checkOut(record1, exitTime: exit1)

        // Day 2: Check in only (still at work)
        let entry2 = Date(timeIntervalSince1970: 3000)
        try repository.checkIn(workplaceId: workplaceId, entryTime: entry2)

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 2)
        XCTAssertNotNil(records[0].exitTime)
        XCTAssertNil(records[1].exitTime)
    }
}
