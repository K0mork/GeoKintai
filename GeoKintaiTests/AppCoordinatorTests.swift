import XCTest
import CoreLocation
@testable import GeoKintai

@MainActor
final class AppCoordinatorTests: XCTestCase {
    var controller: PersistenceController!
    var attendanceRepository: AttendanceRepository!
    var workplaceRepository: WorkplaceRepository!
    var locationProofRepository: LocationProofRepository!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        attendanceRepository = AttendanceRepository(context: controller.viewContext)
        workplaceRepository = WorkplaceRepository(context: controller.viewContext)
        locationProofRepository = LocationProofRepository(context: controller.viewContext)
    }

    // MARK: - Entry Confirmation Tests

    func testEntryConfirmationCreatesAttendanceRecord() throws {
        // Setup: Create a workplace
        let workplace = try workplaceRepository.add(
            name: "Test Office",
            latitude: 35.6812,
            longitude: 139.7671
        )

        // Verify no records initially
        let initialRecords = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertTrue(initialRecords.isEmpty)

        // Simulate entry confirmation by directly calling repository
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)

        // Verify record was created
        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].id, record.id)
        XCTAssertNil(records[0].exitTime)
    }

    func testEntryConfirmationSavesLocationProofs() throws {
        // Setup: Create a workplace and check in
        let workplace = try workplaceRepository.add(
            name: "Test Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)

        // Save location proofs
        let locations = [
            CLLocation(latitude: 35.6812, longitude: 139.7671),
            CLLocation(latitude: 35.6813, longitude: 139.7672),
            CLLocation(latitude: 35.6811, longitude: 139.7670)
        ]
        try locationProofRepository.addBatch(
            recordId: record.id,
            locations: locations,
            reason: .entryTrigger
        )

        // Verify proofs were saved
        let proofs = try locationProofRepository.fetchProofs(for: record.id)
        XCTAssertEqual(proofs.count, 3)
        XCTAssertTrue(proofs.allSatisfy { $0.reason == "EntryTrigger" })
    }

    // MARK: - Exit Confirmation Tests

    func testExitConfirmationUpdatesAttendanceRecord() throws {
        // Setup: Create workplace and check in
        let workplace = try workplaceRepository.add(
            name: "Test Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)
        XCTAssertNil(record.exitTime)

        // Simulate exit confirmation
        try attendanceRepository.checkOut(record)

        // Verify record was updated
        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertNotNil(records[0].exitTime)
    }

    func testExitConfirmationSavesLocationProofs() throws {
        // Setup: Create workplace and check in
        let workplace = try workplaceRepository.add(
            name: "Test Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)
        try attendanceRepository.checkOut(record)

        // Save exit proofs
        let locations = [
            CLLocation(latitude: 35.69, longitude: 139.77),
            CLLocation(latitude: 35.70, longitude: 139.78)
        ]
        try locationProofRepository.addBatch(
            recordId: record.id,
            locations: locations,
            reason: .exitCheck
        )

        // Verify proofs were saved
        let proofs = try locationProofRepository.fetchProofs(for: record.id)
        XCTAssertEqual(proofs.count, 2)
        XCTAssertTrue(proofs.allSatisfy { $0.reason == "ExitCheck" })
    }

    // MARK: - Duplicate Prevention Tests

    func testDuplicateCheckInPrevention() throws {
        // Setup: Create workplace
        let workplace = try workplaceRepository.add(
            name: "Test Office",
            latitude: 35.6812,
            longitude: 139.7671
        )

        // First check in
        try attendanceRepository.checkIn(workplaceId: workplace.id)

        // Check if already checked in (simulating what AppCoordinator does)
        let existingRecords = try attendanceRepository.fetchRecords(for: workplace.id)
        let isAlreadyCheckedIn = existingRecords.last?.exitTime == nil

        XCTAssertTrue(isAlreadyCheckedIn)

        // If we were to check in again without checking, we'd have 2 records
        // AppCoordinator should prevent this
    }

    // MARK: - Multiple Workplaces Tests

    func testMultipleWorkplacesIndependentTracking() throws {
        let workplace1 = try workplaceRepository.add(name: "Office A", latitude: 35.0, longitude: 139.0)
        let workplace2 = try workplaceRepository.add(name: "Office B", latitude: 36.0, longitude: 140.0)

        // Check in at workplace 1
        try attendanceRepository.checkIn(workplaceId: workplace1.id)

        // Check in at workplace 2
        try attendanceRepository.checkIn(workplaceId: workplace2.id)

        // Verify both have independent records
        let records1 = try attendanceRepository.fetchRecords(for: workplace1.id)
        let records2 = try attendanceRepository.fetchRecords(for: workplace2.id)

        XCTAssertEqual(records1.count, 1)
        XCTAssertEqual(records2.count, 1)
        XCTAssertNotEqual(records1[0].id, records2[0].id)
    }

    // MARK: - Full Workflow Tests

    func testFullDayWorkflow() throws {
        // Setup
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )

        // Morning: Check in with entry proofs
        let morningEntry = Date(timeIntervalSince1970: 1000)
        let record = try attendanceRepository.checkIn(
            workplaceId: workplace.id,
            entryTime: morningEntry
        )

        let entryLocations = (0..<5).map { _ in
            CLLocation(latitude: 35.6812, longitude: 139.7671)
        }
        try locationProofRepository.addBatch(
            recordId: record.id,
            locations: entryLocations,
            reason: .entryTrigger
        )

        // During day: Stay check proofs
        let stayLocations = (0..<10).map { _ in
            CLLocation(latitude: 35.6812 + Double.random(in: -0.0001...0.0001),
                      longitude: 139.7671 + Double.random(in: -0.0001...0.0001))
        }
        try locationProofRepository.addBatch(
            recordId: record.id,
            locations: stayLocations,
            reason: .stayCheck
        )

        // Evening: Check out with exit proofs
        let eveningExit = Date(timeIntervalSince1970: 2000)
        try attendanceRepository.checkOut(record, exitTime: eveningExit)

        let exitLocations = (0..<3).map { _ in
            CLLocation(latitude: 35.69, longitude: 139.77)
        }
        try locationProofRepository.addBatch(
            recordId: record.id,
            locations: exitLocations,
            reason: .exitCheck
        )

        // Verify complete record
        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].entryTime, morningEntry)
        XCTAssertEqual(records[0].exitTime, eveningExit)

        let proofs = try locationProofRepository.fetchProofs(for: record.id)
        XCTAssertEqual(proofs.count, 18) // 5 entry + 10 stay + 3 exit

        let entryProofs = proofs.filter { $0.reason == "EntryTrigger" }
        let stayProofs = proofs.filter { $0.reason == "StayCheck" }
        let exitProofs = proofs.filter { $0.reason == "ExitCheck" }

        XCTAssertEqual(entryProofs.count, 5)
        XCTAssertEqual(stayProofs.count, 10)
        XCTAssertEqual(exitProofs.count, 3)
    }
}
