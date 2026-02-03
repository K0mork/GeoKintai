import Foundation
import CoreLocation
import UIKit
@testable import GeoKintai

/// GPXシナリオをシミュレートするためのテストヘルパー
@MainActor
final class SimulationTestHelper {
    let controller: PersistenceController
    let workplaceRepository: WorkplaceRepository
    let attendanceRepository: AttendanceRepository
    let locationProofRepository: LocationProofRepository

    private var locationWrapper: LocationManagerWrapper?
    private var mockLocationManager: SimulationMockLocationManager?
    private var mockApp: SimulationMockApplication?
    private var delegate: SimulationDelegate?

    /// テスト用の仕事場（東京駅）
    static let tokyoStationCoordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    static let defaultRadius: Double = 100.0

    init() {
        controller = PersistenceController(inMemory: true)
        workplaceRepository = WorkplaceRepository(context: controller.viewContext)
        attendanceRepository = AttendanceRepository(context: controller.viewContext)
        locationProofRepository = LocationProofRepository(context: controller.viewContext)
    }

    /// 仕事場を登録
    @discardableResult
    func setupWorkplace(
        name: String = "Tokyo Station",
        coordinate: CLLocationCoordinate2D = tokyoStationCoordinate,
        radius: Double = defaultRadius
    ) throws -> Workplace {
        try workplaceRepository.add(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: radius
        )
    }

    /// LocationManagerWrapperをセットアップ
    func setupLocationManager() -> (wrapper: LocationManagerWrapper, delegate: SimulationDelegate) {
        let mockManager = SimulationMockLocationManager()
        let mockApp = SimulationMockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        let simulationDelegate = SimulationDelegate(
            attendanceRepository: attendanceRepository,
            locationProofRepository: locationProofRepository
        )
        wrapper.delegate = simulationDelegate

        // テスト用に検証時間を短縮
        wrapper.stayVerificationDuration = 0.1
        wrapper.exitVerificationDuration = 0.1

        self.locationWrapper = wrapper
        self.mockLocationManager = mockManager
        self.mockApp = mockApp
        self.delegate = simulationDelegate

        return (wrapper, simulationDelegate)
    }

    /// 仕事場用リージョンを登録
    func registerRegion(for workplace: Workplace) {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: workplace.kLatitude, longitude: workplace.kLongitude),
            radius: workplace.radius,
            identifier: workplace.id.uuidString
        )
        mockLocationManager?.monitoredRegions.insert(region)
    }

    /// GPXファイルのシナリオをシミュレート
    func simulateGPXScenario(
        locations: [CLLocation],
        workplace: Workplace,
        wrapper: LocationManagerWrapper
    ) {
        guard let mockManager = mockLocationManager else { return }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: workplace.kLatitude, longitude: workplace.kLongitude),
            radius: workplace.radius,
            identifier: workplace.id.uuidString
        )
        mockManager.monitoredRegions.insert(region)

        var wasInside = false

        for location in locations {
            let isInside = region.contains(location.coordinate)

            // リージョン境界を越えた時のイベント
            if isInside && !wasInside {
                wrapper.handleDidEnterRegion(region)
            } else if !isInside && wasInside {
                wrapper.handleDidExitRegion(region)
            }

            // 位置更新
            wrapper.handleDidUpdateLocations([location])

            wasInside = isInside
        }
    }

    /// 出勤レコードを取得
    func getAttendanceRecords(for workplaceId: UUID) throws -> [AttendanceRecord] {
        try attendanceRepository.fetchRecords(for: workplaceId)
    }

    /// LocationProofを取得
    func getLocationProofs(for recordId: UUID) throws -> [LocationProof] {
        try locationProofRepository.fetchProofs(for: recordId)
    }
}

// MARK: - Mock Classes for Simulation

final class SimulationMockLocationManager: CLLocationManagerProtocol {
    var delegate: CLLocationManagerDelegate?
    var monitoredRegions: Set<CLRegion> = []

    func startMonitoring(for region: CLRegion) {
        monitoredRegions.insert(region)
    }
    func stopMonitoring(for region: CLRegion) {
        monitoredRegions.remove(region)
    }
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    func requestAlwaysAuthorization() {}
}

final class SimulationMockApplication: ApplicationProtocol {
    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
        UIBackgroundTaskIdentifier(rawValue: 1)
    }
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {}
}

// MARK: - Simulation Delegate

@MainActor
final class SimulationDelegate: LocationManagerWrapperDelegate {
    private let attendanceRepository: AttendanceRepository
    private let locationProofRepository: LocationProofRepository

    var entryConfirmations: [(regionId: String, locations: [CLLocation])] = []
    var exitConfirmations: [(regionId: String, locations: [CLLocation])] = []

    init(attendanceRepository: AttendanceRepository, locationProofRepository: LocationProofRepository) {
        self.attendanceRepository = attendanceRepository
        self.locationProofRepository = locationProofRepository
    }

    func locationManager(_ wrapper: LocationManagerWrapper, didConfirmEntry regionId: String, locations: [CLLocation]) {
        entryConfirmations.append((regionId, locations))

        guard let workplaceId = UUID(uuidString: regionId) else { return }

        do {
            // 既存の未退勤レコードがあれば何もしない
            let existingRecords = try attendanceRepository.fetchRecords(for: workplaceId)
            if let lastRecord = existingRecords.last, lastRecord.exitTime == nil {
                return
            }

            // 新規レコード作成
            let record = try attendanceRepository.checkIn(workplaceId: workplaceId)

            // LocationProof保存
            try locationProofRepository.addBatch(
                recordId: record.id,
                locations: locations,
                reason: .entryTrigger
            )
        } catch {
            print("Entry confirmation error: \(error)")
        }
    }

    func locationManager(_ wrapper: LocationManagerWrapper, didConfirmExit regionId: String, locations: [CLLocation]) {
        exitConfirmations.append((regionId, locations))

        guard let workplaceId = UUID(uuidString: regionId) else { return }

        do {
            let records = try attendanceRepository.fetchRecords(for: workplaceId)
            guard let activeRecord = records.last, activeRecord.exitTime == nil else {
                return
            }

            try attendanceRepository.checkOut(activeRecord)

            try locationProofRepository.addBatch(
                recordId: activeRecord.id,
                locations: locations,
                reason: .exitCheck
            )
        } catch {
            print("Exit confirmation error: \(error)")
        }
    }
}
