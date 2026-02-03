import XCTest
@testable import GeoKintai

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var controller: PersistenceController!
    var attendanceRepository: AttendanceRepository!
    var viewModel: HistoryViewModel!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        attendanceRepository = AttendanceRepository(context: controller.viewContext)
        viewModel = HistoryViewModel(context: controller.viewContext)
    }

    // MARK: - Initial State Tests

    func testInitialStateIsEmpty() {
        XCTAssertTrue(viewModel.records.isEmpty)
        XCTAssertTrue(viewModel.groupedRecords.isEmpty)
        XCTAssertFalse(viewModel.hasRecords)
        XCTAssertEqual(viewModel.totalRecordCount, 0)
    }

    func testInitialStateWithExistingRecords() throws {
        // Add records before creating viewModel
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId)

        let newViewModel = HistoryViewModel(context: controller.viewContext)

        XCTAssertEqual(newViewModel.totalRecordCount, 1)
        XCTAssertTrue(newViewModel.hasRecords)
    }

    // MARK: - Fetch Tests

    func testFetchRecords() throws {
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId)
        try attendanceRepository.checkIn(workplaceId: workplaceId)

        viewModel.fetchRecords()

        XCTAssertEqual(viewModel.totalRecordCount, 2)
    }

    func testFetchRecordsOrderedByEntryTimeDescending() throws {
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 100))
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 300))
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 200))

        viewModel.fetchRecords()

        XCTAssertEqual(viewModel.records[0].entryTime, Date(timeIntervalSince1970: 300))
        XCTAssertEqual(viewModel.records[1].entryTime, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(viewModel.records[2].entryTime, Date(timeIntervalSince1970: 100))
    }

    // MARK: - Grouping Tests

    func testGroupRecordsByDate() throws {
        let workplaceId = UUID()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: today)
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: today.addingTimeInterval(3600))
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: yesterday)

        viewModel.fetchRecords()

        XCTAssertEqual(viewModel.groupedRecords.count, 2)
        XCTAssertEqual(viewModel.records(for: today).count, 2)
        XCTAssertEqual(viewModel.records(for: yesterday).count, 1)
    }

    func testSortedDates() throws {
        let workplaceId = UUID()
        let date1 = Date(timeIntervalSince1970: 86400 * 1) // Day 1
        let date2 = Date(timeIntervalSince1970: 86400 * 3) // Day 3
        let date3 = Date(timeIntervalSince1970: 86400 * 2) // Day 2

        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: date1)
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: date2)
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: date3)

        viewModel.fetchRecords()

        let sortedDates = viewModel.sortedDates
        XCTAssertEqual(sortedDates.count, 3)
        // Should be sorted descending (newest first)
        XCTAssertGreaterThan(sortedDates[0], sortedDates[1])
        XCTAssertGreaterThan(sortedDates[1], sortedDates[2])
    }

    // MARK: - Delete Tests

    func testDeleteRecord() throws {
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId)

        viewModel.fetchRecords()
        XCTAssertEqual(viewModel.totalRecordCount, 1)

        let recordToDelete = viewModel.records[0]
        viewModel.deleteRecord(recordToDelete)

        XCTAssertEqual(viewModel.totalRecordCount, 0)
    }

    func testDeleteOneOfMultipleRecords() throws {
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 100))
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 200))
        try attendanceRepository.checkIn(workplaceId: workplaceId, entryTime: Date(timeIntervalSince1970: 300))

        viewModel.fetchRecords()
        XCTAssertEqual(viewModel.totalRecordCount, 3)

        let recordToDelete = viewModel.records[1] // Middle one
        viewModel.deleteRecord(recordToDelete)

        XCTAssertEqual(viewModel.totalRecordCount, 2)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageIsNilOnSuccess() throws {
        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId)

        viewModel.fetchRecords()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Multiple Workplaces Tests

    func testFetchRecordsFromMultipleWorkplaces() throws {
        let workplace1 = UUID()
        let workplace2 = UUID()

        try attendanceRepository.checkIn(workplaceId: workplace1)
        try attendanceRepository.checkIn(workplaceId: workplace2)
        try attendanceRepository.checkIn(workplaceId: workplace1)

        viewModel.fetchRecords()

        XCTAssertEqual(viewModel.totalRecordCount, 3)
    }

    // MARK: - Edge Cases

    func testRecordsForNonExistentDate() {
        let randomDate = Date(timeIntervalSince1970: 999999999)
        let records = viewModel.records(for: randomDate)
        XCTAssertTrue(records.isEmpty)
    }

    func testHasRecordsProperty() throws {
        XCTAssertFalse(viewModel.hasRecords)

        let workplaceId = UUID()
        try attendanceRepository.checkIn(workplaceId: workplaceId)
        viewModel.fetchRecords()

        XCTAssertTrue(viewModel.hasRecords)
    }
}
