import XCTest
import GeoKintaiCore
@testable import GeoKintaiApp

final class AppStoreIntegrationTests: XCTestCase {
    @MainActor
    func testAppStore_whenPermissionBecomesAlways_startsMonitoringEnabledWorkplace() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "11111111-AAAA-BBBB-CCCC-111111111111")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)

        let monitor = InMemoryRegionMonitor()
        let syncService = RegionMonitoringSyncService(regionMonitor: monitor)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: syncService
        )

        store.permissionStatus = .always

        XCTAssertTrue(store.monitoredWorkplaceIds.contains(workplace.id))
    }

    @MainActor
    func testAppStore_whenWorkplaceMonitoringDisabled_resyncsMonitoredSet() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "22222222-AAAA-BBBB-CCCC-222222222222")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let monitor = InMemoryRegionMonitor()
        let syncService = RegionMonitoringSyncService(regionMonitor: monitor)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: syncService
        )

        store.permissionStatus = .always
        XCTAssertTrue(store.monitoredWorkplaceIds.contains(workplace.id))

        store.setMonitoring(id: workplace.id, enabled: false)

        XCTAssertFalse(store.monitoredWorkplaceIds.contains(workplace.id))
    }

    @MainActor
    func testAppStore_whenPermissionDowngraded_stopsMonitoringAndPreventsAutoRecord() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "33333333-AAAA-BBBB-CCCC-333333333333")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let monitor = InMemoryRegionMonitor()
        let syncService = RegionMonitoringSyncService(regionMonitor: monitor)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: syncService
        )
        store.selectedWorkplaceId = workplace.id

        store.permissionStatus = .always
        XCTAssertTrue(store.monitoredWorkplaceIds.contains(workplace.id))

        store.permissionStatus = .whenInUse
        store.simulateCheckIn()

        XCTAssertTrue(store.monitoredWorkplaceIds.isEmpty)
        XCTAssertEqual(store.attendanceRecords.count, 0)
        XCTAssertTrue(store.lastErrorMessage?.contains("権限") == true)
    }

    @MainActor
    func testAppStore_whenPersistenceWriteFails_preservesExistingDataAndShowsRecoveryMessage() {
        let persistence = PersistenceController()
        let existing = Workplace(
            id: UUID(uuidString: "44444444-AAAA-BBBB-CCCC-444444444444")!,
            name: "Existing",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(existing)
        let writePerformer = FailingWritePerformer(failOnCallNumbers: [1])
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor()),
            writePerformer: writePerformer
        )
        let beforeCount = store.workplaces.count

        store.addWorkplace(
            name: "New Office",
            latitudeText: "35.68",
            longitudeText: "139.76",
            radiusText: "120"
        )

        XCTAssertEqual(store.workplaces.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("保存処理に失敗") == true)
        XCTAssertTrue(store.logs.last?.message.contains("persistenceWriteFailed") == true)
    }

    @MainActor
    func testAppStore_whenRetryAfterPersistenceWriteFailure_succeedsOnNextAttempt() {
        let persistence = PersistenceController()
        let existing = Workplace(
            id: UUID(uuidString: "55555555-AAAA-BBBB-CCCC-555555555555")!,
            name: "Existing",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(existing)
        let writePerformer = FailingWritePerformer(failOnCallNumbers: [1])
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor()),
            writePerformer: writePerformer
        )

        store.addWorkplace(
            name: "Retry Office",
            latitudeText: "35.68",
            longitudeText: "139.76",
            radiusText: "120"
        )
        XCTAssertTrue(store.lastErrorMessage?.contains("保存処理に失敗") == true)

        store.addWorkplace(
            name: "Retry Office",
            latitudeText: "35.68",
            longitudeText: "139.76",
            radiusText: "120"
        )

        XCTAssertTrue(store.workplaces.contains(where: { $0.name == "Retry Office" }))
        XCTAssertNil(store.lastErrorMessage)
    }
}

private struct FailingWritePerformerError: Error {}

private final class FailingWritePerformer: PersistenceWritePerformer {
    private var calledCount = 0
    private let failOnCallNumbers: Set<Int>

    init(failOnCallNumbers: Set<Int>) {
        self.failOnCallNumbers = failOnCallNumbers
    }

    func perform<T>(_ action: () -> T) throws -> T {
        calledCount += 1
        if failOnCallNumbers.contains(calledCount) {
            throw FailingWritePerformerError()
        }
        return action()
    }
}
