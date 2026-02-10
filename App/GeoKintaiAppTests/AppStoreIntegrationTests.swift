import XCTest
import GeoKintaiCore
import UIKit
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
    func testAppStore_whenPermissionAlways_requestsRegionStateForMonitoredWorkplace() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "11111111-AAAA-BBBB-CCCC-222222222222")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let backgroundClient = BackgroundLocationClientSpy()
        let syncService = RegionMonitoringSyncService(regionMonitor: backgroundClient)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: syncService,
            backgroundLocationClient: backgroundClient
        )

        store.permissionStatus = .always

        XCTAssertTrue(store.monitoredWorkplaceIds.contains(workplace.id))
        XCTAssertTrue(backgroundClient.requestedStateWorkplaceIds.contains(workplace.id))
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
    func testAppStore_whenDeleteWorkplace_removesFromMonitoringSet() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "22222222-AAAA-BBBB-CCCC-999999999999")!,
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

        store.deleteWorkplace(id: workplace.id)

        XCTAssertFalse(store.monitoredWorkplaceIds.contains(workplace.id))
        XCTAssertFalse(store.workplaces.contains(where: { $0.id == workplace.id }))
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
    func testAppStore_whenLaunchInsideWorkplace_for5Minutes_createsAttendanceAutomatically() {
        let clock = TestVerificationClock(now: Date(timeIntervalSince1970: 1_701_000_000))
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "33333333-AAAA-BBBB-CCCC-444444444444")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let backgroundClient = BackgroundLocationClientSpy()
        let syncService = RegionMonitoringSyncService(regionMonitor: backgroundClient)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: clock,
            regionMonitoringSyncService: syncService,
            backgroundLocationClient: backgroundClient
        )
        store.permissionStatus = .always

        backgroundClient.emitDidDetermineState(workplaceId: workplace.id, isInside: true)
        backgroundClient.emitLocation(latitude: 35.0, longitude: 139.0)
        clock.advance(seconds: 300)
        backgroundClient.emitLocation(latitude: 35.0, longitude: 139.0)

        XCTAssertEqual(store.attendanceRecords.count, 1)
        XCTAssertEqual(store.attendanceRecords[0].workplaceId, workplace.id)
        XCTAssertEqual(store.proofs.first?.reason, .stayCheck)
        XCTAssertTrue(store.logs.contains(where: { $0.message.contains("didEnterRegion") }))
        XCTAssertTrue(store.logs.contains(where: { $0.message.contains("stayConfirmed") }))
        XCTAssertGreaterThanOrEqual(backgroundClient.startUpdatingLocationCallCount, 1)
        XCTAssertGreaterThanOrEqual(backgroundClient.stopUpdatingLocationCallCount, 1)
    }

    @MainActor
    func testAppStore_whenLaunchInsideButLeaveEarly_doesNotCreateAttendance() {
        let clock = TestVerificationClock(now: Date(timeIntervalSince1970: 1_701_010_000))
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "33333333-AAAA-BBBB-CCCC-555555555555")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let backgroundClient = BackgroundLocationClientSpy()
        let syncService = RegionMonitoringSyncService(regionMonitor: backgroundClient)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: clock,
            regionMonitoringSyncService: syncService,
            backgroundLocationClient: backgroundClient
        )
        store.permissionStatus = .always

        backgroundClient.emitDidDetermineState(workplaceId: workplace.id, isInside: true)
        backgroundClient.emitLocation(latitude: 35.0, longitude: 139.0)
        clock.advance(seconds: 120)
        backgroundClient.emitLocation(latitude: 35.003, longitude: 139.003)

        XCTAssertEqual(store.attendanceRecords.count, 0)
        XCTAssertEqual(store.proofs.count, 0)
        XCTAssertGreaterThanOrEqual(backgroundClient.stopUpdatingLocationCallCount, 1)
    }

    @MainActor
    func testAppStore_whenLocationUnavailable_showsRetryMessageAndLogsFailure() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "33333333-AAAA-BBBB-CCCC-666666666666")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let backgroundClient = BackgroundLocationClientSpy()
        let syncService = RegionMonitoringSyncService(regionMonitor: backgroundClient)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: syncService,
            backgroundLocationClient: backgroundClient
        )
        store.permissionStatus = .always

        backgroundClient.emitLocationError(message: "timeout")

        XCTAssertTrue(store.lastErrorMessage?.contains("位置情報の取得に失敗") == true)
        XCTAssertTrue(store.logs.contains(where: { $0.message.contains("locationUnavailable") }))
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

    @MainActor
    func testAppStore_whenUpdateWorkplaceWithValidInput_updatesStoredValues() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "66666666-AAAA-BBBB-CCCC-666666666666")!,
            name: "Old Name",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )

        store.updateWorkplace(
            id: workplace.id,
            name: "New Name",
            latitudeText: "34.5",
            longitudeText: "135.5",
            radiusText: "250"
        )

        guard let updated = store.workplaces.first(where: { $0.id == workplace.id }) else {
            XCTFail("Updated workplace not found")
            return
        }
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.latitude, 34.5, accuracy: 0.0001)
        XCTAssertEqual(updated.longitude, 135.5, accuracy: 0.0001)
        XCTAssertEqual(updated.radius, 250, accuracy: 0.0001)
    }

    @MainActor
    func testAppStore_whenUpdateWorkplaceTargetMissing_setsError() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )

        store.updateWorkplace(
            id: UUID(uuidString: "99999999-AAAA-BBBB-CCCC-999999999999")!,
            name: "New Name",
            latitudeText: "34.5",
            longitudeText: "135.5",
            radiusText: "250"
        )

        XCTAssertTrue(store.lastErrorMessage?.contains("対象の仕事場が見つかりません") == true)
    }

    @MainActor
    func testAppStore_whenUpdateWorkplaceLongitudeOutOfRange_rejectsUpdate() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "66666666-AAAA-BBBB-CCCC-777777777777")!,
            name: "Old Name",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )

        store.updateWorkplace(
            id: workplace.id,
            name: "Updated Name",
            latitudeText: "34.5",
            longitudeText: "181.0",
            radiusText: "250"
        )

        guard let unchanged = store.workplaces.first(where: { $0.id == workplace.id }) else {
            XCTFail("Workplace not found")
            return
        }
        XCTAssertEqual(unchanged.name, "Old Name")
        XCTAssertEqual(unchanged.longitude, 139.0, accuracy: 0.0001)
        XCTAssertTrue(store.lastErrorMessage?.contains("経度は -180 〜 180") == true)
    }

    @MainActor
    func testAppStore_whenAddWorkplaceLatitudeOutOfRange_rejectsSave() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.workplaces.count

        store.addWorkplace(
            name: "Invalid Lat",
            latitudeText: "91.0",
            longitudeText: "139.76",
            radiusText: "120"
        )

        XCTAssertEqual(store.workplaces.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("緯度は -90 〜 90") == true)
    }

    @MainActor
    func testAppStore_whenAddWorkplaceLongitudeOutOfRange_rejectsSave() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.workplaces.count

        store.addWorkplace(
            name: "Invalid Lon",
            latitudeText: "35.68",
            longitudeText: "181.0",
            radiusText: "120"
        )

        XCTAssertEqual(store.workplaces.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("経度は -180 〜 180") == true)
    }

    @MainActor
    func testAppStore_whenAddWorkplaceCoordinateHasWhitespace_savesSuccessfully() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.workplaces.count

        store.addWorkplace(
            name: "Whitespace Coordinate",
            latitudeText: " 35.68 ",
            longitudeText: "\n139.76\t",
            radiusText: "120"
        )

        XCTAssertEqual(store.workplaces.count, beforeCount + 1)
        XCTAssertNil(store.lastErrorMessage)
    }

    @MainActor
    func testAppStore_whenSimulateCheckOutWithoutOpenRecord_showsError() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        store.selectedWorkplaceId = workplace.id
        store.permissionStatus = .always

        store.simulateCheckOut()

        XCTAssertEqual(store.attendanceRecords.count, 0)
        XCTAssertTrue(store.lastErrorMessage?.contains("勤務中レコードがありません") == true)
    }

    @MainActor
    func testAppStore_whenManualCorrectionReasonEmpty_rejectsAppend() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "77777777-AAAA-BBBB-CCCC-777777777777")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let record = persistence.attendance.createOpenRecord(
            workplaceId: workplace.id,
            entryTime: Date(timeIntervalSince1970: 1_700_600_000)
        )
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.corrections.count

        store.addManualCorrection(
            recordId: record.id,
            reason: "  ",
            correctedEntryTime: Date(timeIntervalSince1970: 1_700_600_100),
            correctedExitTime: nil
        )

        XCTAssertEqual(store.corrections.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("理由") == true)
    }

    @MainActor
    func testAppStore_whenManualCorrectionExitEarlierThanEntry_rejectsAppend() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "77777777-AAAA-BBBB-CCCC-171717171717")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let record = persistence.attendance.createOpenRecord(
            workplaceId: workplace.id,
            entryTime: Date(timeIntervalSince1970: 1_700_610_000)
        )
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.corrections.count
        let correctedEntry = Date(timeIntervalSince1970: 1_700_610_100)
        let correctedExit = Date(timeIntervalSince1970: 1_700_610_050)

        store.addManualCorrection(
            recordId: record.id,
            reason: "逆転時刻",
            correctedEntryTime: correctedEntry,
            correctedExitTime: correctedExit
        )

        XCTAssertEqual(store.corrections.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("退勤時刻は出勤時刻以降") == true)
    }

    @MainActor
    func testAppStore_whenManualCorrectionRecordMissing_rejectsAppend() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )
        let beforeCount = store.corrections.count

        store.addManualCorrection(
            recordId: UUID(uuidString: "99999999-1111-2222-3333-444444444444")!,
            reason: "存在しない記録",
            correctedEntryTime: Date(timeIntervalSince1970: 1_700_620_000),
            correctedExitTime: nil
        )

        XCTAssertEqual(store.corrections.count, beforeCount)
        XCTAssertTrue(store.lastErrorMessage?.contains("修正対象の勤務レコードが見つかりません") == true)
    }

    @MainActor
    func testAppStore_whenManualCorrectionValid_appendsCorrection() {
        let persistence = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "88888888-AAAA-BBBB-CCCC-888888888888")!,
            name: "Office",
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        let entry = Date(timeIntervalSince1970: 1_700_700_000)
        let record = persistence.attendance.createOpenRecord(
            workplaceId: workplace.id,
            entryTime: entry
        )
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )

        store.addManualCorrection(
            recordId: record.id,
            reason: "打刻補正",
            correctedEntryTime: entry.addingTimeInterval(120),
            correctedExitTime: nil
        )

        XCTAssertEqual(store.corrections.count, 1)
        XCTAssertEqual(store.corrections[0].attendanceRecordId, record.id)
        XCTAssertEqual(store.corrections[0].reason, "打刻補正")
        XCTAssertFalse(store.corrections[0].integrityHash.isEmpty)
    }

    @MainActor
    func testAppStore_whenExportCSVNoData_showsReadableError() {
        let persistence = PersistenceController()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor())
        )

        store.exportCSV()

        XCTAssertNil(store.lastExport)
        XCTAssertTrue(store.lastErrorMessage?.contains("出力対象データがありません") == true)
    }

    @MainActor
    func testAppStore_whenGuidanceIsOpenSettings_opensSystemSettings() {
        let persistence = PersistenceController()
        let opener = URLHandlerSpy()
        let store = AppStore(
            persistence: persistence,
            permissionUseCase: PermissionUseCase(),
            clock: SystemVerificationClock(),
            regionMonitoringSyncService: RegionMonitoringSyncService(regionMonitor: InMemoryRegionMonitor()),
            urlHandler: opener
        )
        store.permissionStatus = .denied

        store.openAppSettings()

        XCTAssertEqual(opener.openedURLs.last?.absoluteString, UIApplication.openSettingsURLString)
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

private final class URLHandlerSpy: URLHandling {
    var openedURLs: [URL] = []

    @discardableResult
    func open(_ url: URL) -> Bool {
        openedURLs.append(url)
        return true
    }
}

private final class TestVerificationClock: VerificationClock {
    private var current: Date

    init(now: Date) {
        self.current = now
    }

    var now: Date {
        current
    }

    func advance(seconds: TimeInterval) {
        current = current.addingTimeInterval(seconds)
    }
}

private final class BackgroundLocationClientSpy: BackgroundLocationClient {
    var onAuthorizationChanged: ((LocationPermissionStatus) -> Void)?
    var onDidEnterRegion: ((UUID) -> Void)?
    var onDidExitRegion: ((UUID) -> Void)?
    var onDidDetermineState: ((UUID, Bool) -> Void)?
    var onLocationUpdate: ((LocationCoordinateSample) -> Void)?
    var onLocationError: ((String) -> Void)?

    private var regionsByWorkplaceId: [UUID: MonitoredRegion] = [:]
    private var currentStatus: LocationPermissionStatus = .notDetermined

    private(set) var requestAlwaysAuthorizationCallCount = 0
    private(set) var startUpdatingLocationCallCount = 0
    private(set) var stopUpdatingLocationCallCount = 0
    private(set) var requestedStateWorkplaceIds: [UUID] = []

    func currentPermissionStatus() -> LocationPermissionStatus {
        currentStatus
    }

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCallCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingLocationCallCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }

    func requestState(for workplaceId: UUID) {
        requestedStateWorkplaceIds.append(workplaceId)
    }

    func startMonitoring(region: MonitoredRegion) {
        regionsByWorkplaceId[region.workplaceId] = region
    }

    func stopMonitoring(workplaceId: UUID) {
        regionsByWorkplaceId.removeValue(forKey: workplaceId)
    }

    func monitoredWorkplaceIds() -> Set<UUID> {
        Set(regionsByWorkplaceId.keys)
    }

    func emitAuthorization(status: LocationPermissionStatus) {
        currentStatus = status
        onAuthorizationChanged?(status)
    }

    func emitDidEnter(workplaceId: UUID) {
        onDidEnterRegion?(workplaceId)
    }

    func emitDidExit(workplaceId: UUID) {
        onDidExitRegion?(workplaceId)
    }

    func emitDidDetermineState(workplaceId: UUID, isInside: Bool) {
        onDidDetermineState?(workplaceId, isInside)
    }

    func emitLocation(latitude: Double, longitude: Double, accuracy: Double = 5) {
        onLocationUpdate?(
            LocationCoordinateSample(
                timestamp: Date(timeIntervalSince1970: 1_701_000_000),
                latitude: latitude,
                longitude: longitude,
                horizontalAccuracy: accuracy
            )
        )
    }

    func emitLocationError(message: String) {
        onLocationError?(message)
    }
}
