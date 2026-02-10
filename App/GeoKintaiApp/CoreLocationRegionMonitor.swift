import CoreLocation
import Foundation
import GeoKintaiCore

final class CoreLocationRegionMonitor: NSObject, BackgroundLocationClient {
    var onAuthorizationChanged: ((LocationPermissionStatus) -> Void)?
    var onDidEnterRegion: ((UUID) -> Void)?
    var onDidExitRegion: ((UUID) -> Void)?
    var onDidDetermineState: ((UUID, Bool) -> Void)?
    var onLocationUpdate: ((LocationCoordinateSample) -> Void)?
    var onLocationError: ((String) -> Void)?

    private let locationManager: CLLocationManager
    private var regionsByWorkplaceId: [UUID: CLCircularRegion] = [:]

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func currentPermissionStatus() -> LocationPermissionStatus {
        Self.mapAuthorizationStatus(locationManager.authorizationStatus)
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func requestState(for workplaceId: UUID) {
        guard let region = regionFor(workplaceId: workplaceId) else {
            return
        }
        locationManager.requestState(for: region)
    }

    func startMonitoring(region: MonitoredRegion) {
        let circular = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: region.latitude, longitude: region.longitude),
            radius: max(1, region.radius),
            identifier: region.workplaceId.uuidString
        )
        circular.notifyOnEntry = true
        circular.notifyOnExit = true
        regionsByWorkplaceId[region.workplaceId] = circular
        locationManager.startMonitoring(for: circular)
    }

    func stopMonitoring(workplaceId: UUID) {
        if let region = regionsByWorkplaceId.removeValue(forKey: workplaceId) {
            locationManager.stopMonitoring(for: region)
            return
        }

        guard let region = locationManager.monitoredRegions.first(where: { $0.identifier == workplaceId.uuidString }) else {
            return
        }
        locationManager.stopMonitoring(for: region)
    }

    func monitoredWorkplaceIds() -> Set<UUID> {
        syncRegionsFromManager()
        return Set(regionsByWorkplaceId.keys)
    }

    private func syncRegionsFromManager() {
        var next: [UUID: CLCircularRegion] = [:]
        for region in locationManager.monitoredRegions {
            guard
                let id = UUID(uuidString: region.identifier),
                let circular = region as? CLCircularRegion
            else {
                continue
            }
            next[id] = circular
        }
        if !next.isEmpty {
            regionsByWorkplaceId = next
        }
    }

    private func regionFor(workplaceId: UUID) -> CLCircularRegion? {
        if let region = regionsByWorkplaceId[workplaceId] {
            return region
        }
        syncRegionsFromManager()
        return regionsByWorkplaceId[workplaceId]
    }

    private static func mapAuthorizationStatus(_ status: CLAuthorizationStatus) -> LocationPermissionStatus {
        switch status {
        case .authorizedAlways:
            return .always
        case .authorizedWhenInUse:
            return .whenInUse
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func workplaceId(from region: CLRegion) -> UUID? {
        UUID(uuidString: region.identifier)
    }
}

extension CoreLocationRegionMonitor: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChanged?(Self.mapAuthorizationStatus(manager.authorizationStatus))
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let workplaceId = workplaceId(from: region) else {
            return
        }
        onDidEnterRegion?(workplaceId)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let workplaceId = workplaceId(from: region) else {
            return
        }
        onDidExitRegion?(workplaceId)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let workplaceId = workplaceId(from: region) else {
            return
        }
        onDidDetermineState?(workplaceId, state == .inside)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        let sample = LocationCoordinateSample(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy
        )
        onLocationUpdate?(sample)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        onLocationError?(error.localizedDescription)
    }
}
