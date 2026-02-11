import Foundation
import GeoKintaiCore

struct LocationCoordinateSample: Equatable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
}

protocol BackgroundLocationClient: AnyObject, RegionMonitor {
    var onAuthorizationChanged: ((LocationPermissionStatus) -> Void)? { get set }
    var onDidEnterRegion: ((UUID) -> Void)? { get set }
    var onDidExitRegion: ((UUID) -> Void)? { get set }
    var onDidDetermineState: ((UUID, Bool) -> Void)? { get set }
    var onLocationUpdate: ((LocationCoordinateSample) -> Void)? { get set }
    var onLocationError: ((String) -> Void)? { get set }

    func currentPermissionStatus() -> LocationPermissionStatus
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestState(for workplaceId: UUID)
}

final class NoopBackgroundLocationClient: BackgroundLocationClient {
    var onAuthorizationChanged: ((LocationPermissionStatus) -> Void)?
    var onDidEnterRegion: ((UUID) -> Void)?
    var onDidExitRegion: ((UUID) -> Void)?
    var onDidDetermineState: ((UUID, Bool) -> Void)?
    var onLocationUpdate: ((LocationCoordinateSample) -> Void)?
    var onLocationError: ((String) -> Void)?

    private var regionsByWorkplaceId: [UUID: MonitoredRegion] = [:]

    func currentPermissionStatus() -> LocationPermissionStatus {
        .notDetermined
    }

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    func requestState(for workplaceId: UUID) {}

    func startMonitoring(region: MonitoredRegion) {
        regionsByWorkplaceId[region.workplaceId] = region
    }

    func stopMonitoring(workplaceId: UUID) {
        regionsByWorkplaceId.removeValue(forKey: workplaceId)
    }

    func monitoredWorkplaceIds() -> Set<UUID> {
        Set(regionsByWorkplaceId.keys)
    }

    func monitoredRegions() -> [UUID: MonitoredRegion] {
        regionsByWorkplaceId
    }
}
