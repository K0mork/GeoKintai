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

    func testInitialStatusIsOffDuty() async throws {
        XCTAssertEqual(viewModel.status, .offDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check In")
    }

    func testCheckInSetsStatusOnDuty() async throws {
        try viewModel.checkIn()
        XCTAssertEqual(viewModel.status, .onDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check Out")
    }

    func testCheckOutSetsStatusOffDuty() async throws {
        try viewModel.checkIn()
        try viewModel.checkOut()
        XCTAssertEqual(viewModel.status, .offDuty)
        XCTAssertEqual(viewModel.actionTitle, "Check In")
    }

    func testPrimaryActionTogglesStatus() async throws {
        try viewModel.performPrimaryAction()
        XCTAssertEqual(viewModel.status, .onDuty)
        try viewModel.performPrimaryAction()
        XCTAssertEqual(viewModel.status, .offDuty)
    }

    func testSectionStrings() async throws {
        XCTAssertEqual(viewModel.sectionTitle, "Status")
        XCTAssertEqual(viewModel.sectionDescription, "Current attendance status.")
    }
}
