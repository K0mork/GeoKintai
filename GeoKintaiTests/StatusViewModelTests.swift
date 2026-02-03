import XCTest
@testable import GeoKintai

@MainActor
final class StatusViewModelTests: XCTestCase {
    var controller: PersistenceController!
    var repository: AttendanceRepository!
    var workplaceId: UUID!
    var viewModel: StatusViewModel!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        repository = AttendanceRepository(context: controller.viewContext)
        workplaceId = UUID()
        viewModel = StatusViewModel(repository: repository, workplaceId: workplaceId)
    }

    // MARK: - Initial State Tests

    func testInitialStatusIsOffDuty() async throws {
        XCTAssertEqual(viewModel.status, .offDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check In")
    }

    func testInitialStatusWithExistingOpenRecord() async throws {
        try repository.checkIn(workplaceId: workplaceId)

        let newViewModel = StatusViewModel(repository: repository, workplaceId: workplaceId)
        XCTAssertEqual(newViewModel.status, .onDuty)
    }

    func testInitialStatusWithClosedRecord() async throws {
        let record = try repository.checkIn(workplaceId: workplaceId)
        try repository.checkOut(record)

        let newViewModel = StatusViewModel(repository: repository, workplaceId: workplaceId)
        XCTAssertEqual(newViewModel.status, .offDuty)
    }

    // MARK: - Check In Tests

    func testCheckInSetsStatusOnDuty() async throws {
        try viewModel.checkIn()
        XCTAssertEqual(viewModel.status, .onDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check Out")
    }

    func testCheckInCreatesRecord() async throws {
        try viewModel.checkIn()

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 1)
        XCTAssertNil(records[0].exitTime)
    }

    // MARK: - Check Out Tests

    func testCheckOutSetsStatusOffDuty() async throws {
        try viewModel.checkIn()
        try viewModel.checkOut()
        XCTAssertEqual(viewModel.status, .offDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check In")
    }

    func testCheckOutUpdatesRecord() async throws {
        try viewModel.checkIn()
        try viewModel.checkOut()

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 1)
        XCTAssertNotNil(records[0].exitTime)
    }

    func testCheckOutWithNoOpenRecordDoesNothing() async throws {
        try viewModel.checkOut()
        XCTAssertEqual(viewModel.status, .offDuty)
    }

    // MARK: - Primary Action Tests

    func testPrimaryActionTogglesStatus() async throws {
        try viewModel.performPrimaryAction()
        XCTAssertEqual(viewModel.status, .onDuty)
        try viewModel.performPrimaryAction()
        XCTAssertEqual(viewModel.status, .offDuty)
    }

    func testPrimaryActionMultipleCycles() async throws {
        for _ in 0..<3 {
            try viewModel.performPrimaryAction() // Check in
            XCTAssertEqual(viewModel.status, .onDuty)
            try viewModel.performPrimaryAction() // Check out
            XCTAssertEqual(viewModel.status, .offDuty)
        }

        let records = try repository.fetchRecords(for: workplaceId)
        XCTAssertEqual(records.count, 3)
    }

    // MARK: - Status Text Tests

    func testSectionStrings() async throws {
        XCTAssertEqual(viewModel.sectionTitle, "Status")
        XCTAssertEqual(viewModel.sectionDescription, "Current attendance status.")
    }

    func testStatusTextOffDuty() async throws {
        XCTAssertEqual(viewModel.statusText, "Off Duty")
    }

    func testStatusTextOnDuty() async throws {
        try viewModel.checkIn()
        XCTAssertEqual(viewModel.statusText, "On Duty")
    }

    // MARK: - Error Handling Tests

    func testClearError() async throws {
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Update Status Tests

    func testUpdateStatusReflectsExternalChanges() async throws {
        // External change (simulating background update)
        try repository.checkIn(workplaceId: workplaceId)

        // ViewModel should still show old status
        XCTAssertEqual(viewModel.status, .offDuty)

        // After update, should reflect new status
        viewModel.updateStatus()
        XCTAssertEqual(viewModel.status, .onDuty)
    }

    // MARK: - Multiple Workplaces Tests

    func testStatusIsIsolatedPerWorkplace() async throws {
        let workplace1 = UUID()
        let workplace2 = UUID()

        let vm1 = StatusViewModel(repository: repository, workplaceId: workplace1)
        let vm2 = StatusViewModel(repository: repository, workplaceId: workplace2)

        try vm1.checkIn()

        XCTAssertEqual(vm1.status, .onDuty)
        XCTAssertEqual(vm2.status, .offDuty)
    }
}
