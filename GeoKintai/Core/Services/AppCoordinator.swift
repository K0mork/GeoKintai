import Foundation
import CoreLocation
import CoreData

@MainActor
public final class AppCoordinator: NSObject, LocationManagerWrapperDelegate {
    public static let shared = AppCoordinator()

    private let persistenceController: PersistenceController
    private let locationManager: LocationManagerWrapper
    private lazy var attendanceRepository: AttendanceRepository = {
        AttendanceRepository(context: persistenceController.viewContext)
    }()
    private lazy var locationProofRepository: LocationProofRepository = {
        LocationProofRepository(context: persistenceController.viewContext)
    }()
    private lazy var workplaceRepository: WorkplaceRepository = {
        WorkplaceRepository(context: persistenceController.viewContext)
    }()

    private var activeRecords: [String: AttendanceRecord] = [:]

    private override init() {
        self.persistenceController = PersistenceController.shared
        self.locationManager = LocationManagerWrapper()
        super.init()
        self.locationManager.delegate = self
    }

    // MARK: - Public API

    public func start() {
        locationManager.requestAuthorization()
        syncRegions()
    }

    public func syncRegions() {
        do {
            let workplaces = try workplaceRepository.fetchAll()
                .filter { $0.monitoringEnabled }
                .map { (id: $0.id, latitude: $0.kLatitude, longitude: $0.kLongitude, radius: $0.radius) }
            locationManager.syncMonitoredRegions(with: workplaces)
        } catch {
            print("Failed to sync regions: \(error)")
        }
    }

    // MARK: - LocationManagerWrapperDelegate

    public func locationManager(_ wrapper: LocationManagerWrapper, didConfirmEntry regionId: String, locations: [CLLocation]) {
        guard let workplaceId = UUID(uuidString: regionId) else { return }

        do {
            // Check if already checked in
            let existingRecords = try attendanceRepository.fetchRecords(for: workplaceId)
            if let lastRecord = existingRecords.last, lastRecord.exitTime == nil {
                // Already checked in
                return
            }

            // Create new attendance record
            let record = try attendanceRepository.checkIn(workplaceId: workplaceId)
            activeRecords[regionId] = record

            // Save location proofs
            try locationProofRepository.addBatch(
                recordId: record.id,
                locations: locations,
                reason: .entryTrigger
            )

            // TODO: Send local notification
            print("✅ Checked in at \(regionId)")
        } catch {
            print("Failed to check in: \(error)")
        }
    }

    public func locationManager(_ wrapper: LocationManagerWrapper, didConfirmExit regionId: String, locations: [CLLocation]) {
        guard let workplaceId = UUID(uuidString: regionId) else { return }

        do {
            // Find active record
            let records = try attendanceRepository.fetchRecords(for: workplaceId)
            guard let activeRecord = records.last, activeRecord.exitTime == nil else {
                return
            }

            // Check out
            try attendanceRepository.checkOut(activeRecord)
            activeRecords.removeValue(forKey: regionId)

            // Save exit proofs
            try locationProofRepository.addBatch(
                recordId: activeRecord.id,
                locations: locations,
                reason: .exitCheck
            )

            // TODO: Send local notification
            print("✅ Checked out from \(regionId)")
        } catch {
            print("Failed to check out: \(error)")
        }
    }
}
