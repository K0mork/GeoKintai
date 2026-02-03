import XCTest
import CoreLocation
@testable import GeoKintai

@MainActor
final class AppCoordinatorTests: XCTestCase {
    var controller: PersistenceController!
    var attendanceRepository: AttendanceRepository!
    var workplaceRepository: WorkplaceRepository!
    var locationProofRepository: LocationProofRepository!
    var mockManager: MockLocationManager!
    var wrapper: LocationManagerWrapper!
    var coordinator: AppCoordinator!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        attendanceRepository = AttendanceRepository(context: controller.viewContext)
        workplaceRepository = WorkplaceRepository(context: controller.viewContext)
        locationProofRepository = LocationProofRepository(context: controller.viewContext)
        mockManager = MockLocationManager()
        wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        coordinator = AppCoordinator(
            persistenceController: controller,
            locationManager: wrapper,
            attendanceRepository: attendanceRepository,
            locationProofRepository: locationProofRepository,
            workplaceRepository: workplaceRepository
        )
    }

    // MARK: - Start / Sync Tests

    func testStartRequestsAuthorizationAndSyncsRegions() throws {
        let enabled = try workplaceRepository.add(
            name: "Enabled",
            latitude: 35.0,
            longitude: 139.0,
            monitoringEnabled: true
        )
        _ = try workplaceRepository.add(
            name: "Disabled",
            latitude: 36.0,
            longitude: 140.0,
            monitoringEnabled: false
        )

        coordinator.start()

        XCTAssertTrue(mockManager.didRequestAlwaysAuth)
        XCTAssertEqual(mockManager.monitoredRegions.count, 1)
        let identifiers = Set(mockManager.monitoredRegions.map(\.identifier))
        XCTAssertTrue(identifiers.contains(enabled.id.uuidString))
    }

    func testSyncRegionsFiltersMonitoringEnabled() throws {
        let enabled = try workplaceRepository.add(
            name: "Enabled",
            latitude: 35.0,
            longitude: 139.0,
            monitoringEnabled: true
        )
        _ = try workplaceRepository.add(
            name: "Disabled",
            latitude: 36.0,
            longitude: 140.0,
            monitoringEnabled: false
        )

        coordinator.syncRegions()

        XCTAssertEqual(mockManager.monitoredRegions.count, 1)
        let identifiers = Set(mockManager.monitoredRegions.map(\.identifier))
        XCTAssertTrue(identifiers.contains(enabled.id.uuidString))
    }

    // MARK: - Entry Tests

    func testDidConfirmEntryCreatesRecordAndProofs() throws {
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let locations = [
            CLLocation(latitude: 35.6812, longitude: 139.7671),
            CLLocation(latitude: 35.6813, longitude: 139.7672)
        ]

        coordinator.locationManager(wrapper, didConfirmEntry: workplace.id.uuidString, locations: locations)

        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertNil(records.first?.exitTime)

        let proofs = try locationProofRepository.fetchProofs(for: records[0].id)
        XCTAssertEqual(proofs.count, 2)
        XCTAssertTrue(proofs.allSatisfy { $0.reason == "EntryTrigger" })
    }

    func testDidConfirmEntryDoesNotDuplicateWhenOpenRecordExists() throws {
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        _ = try attendanceRepository.checkIn(workplaceId: workplace.id)

        let locations = [CLLocation(latitude: 35.6812, longitude: 139.7671)]
        coordinator.locationManager(wrapper, didConfirmEntry: workplace.id.uuidString, locations: locations)

        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)

        let proofs = try locationProofRepository.fetchProofs(for: records[0].id)
        XCTAssertTrue(proofs.isEmpty)
    }

    func testDidConfirmEntryIgnoresInvalidRegionId() throws {
        let locations = [CLLocation(latitude: 35.6812, longitude: 139.7671)]

        coordinator.locationManager(wrapper, didConfirmEntry: "invalid-uuid", locations: locations)

        let records = try attendanceRepository.fetchRecords(for: UUID())
        XCTAssertTrue(records.isEmpty)
    }

    // MARK: - Exit Tests

    func testDidConfirmExitChecksOutAndSavesProofs() throws {
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)

        let locations = [
            CLLocation(latitude: 35.69, longitude: 139.77),
            CLLocation(latitude: 35.70, longitude: 139.78)
        ]
        coordinator.locationManager(wrapper, didConfirmExit: workplace.id.uuidString, locations: locations)

        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertNotNil(records[0].exitTime)

        let proofs = try locationProofRepository.fetchProofs(for: record.id)
        XCTAssertEqual(proofs.count, 2)
        XCTAssertTrue(proofs.allSatisfy { $0.reason == "ExitCheck" })
    }

    func testDidConfirmExitDoesNothingWhenNoActiveRecord() throws {
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let locations = [CLLocation(latitude: 35.69, longitude: 139.77)]

        coordinator.locationManager(wrapper, didConfirmExit: workplace.id.uuidString, locations: locations)

        let records = try attendanceRepository.fetchRecords(for: workplace.id)
        XCTAssertTrue(records.isEmpty)
    }

    func testDidConfirmExitDoesNothingWhenRecordAlreadyClosed() throws {
        let workplace = try workplaceRepository.add(
            name: "Office",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let record = try attendanceRepository.checkIn(workplaceId: workplace.id)
        try attendanceRepository.checkOut(record)

        let locations = [CLLocation(latitude: 35.69, longitude: 139.77)]
        coordinator.locationManager(wrapper, didConfirmExit: workplace.id.uuidString, locations: locations)

        let proofs = try locationProofRepository.fetchProofs(for: record.id)
        XCTAssertTrue(proofs.isEmpty)
    }

    func testDidConfirmExitIgnoresInvalidRegionId() throws {
        let locations = [CLLocation(latitude: 35.69, longitude: 139.77)]

        coordinator.locationManager(wrapper, didConfirmExit: "invalid-uuid", locations: locations)

        let records = try attendanceRepository.fetchRecords(for: UUID())
        XCTAssertTrue(records.isEmpty)
    }
}
