// LocationManagerWrapper.swift
import Foundation
import CoreLocation
import UIKit

public protocol CLLocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var monitoredRegions: Set<CLRegion> { get }
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestAlwaysAuthorization()
}

extension CLLocationManager: CLLocationManagerProtocol {}

public protocol ApplicationProtocol: AnyObject {
    func beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: ApplicationProtocol {}

public protocol TimerProtocol {
    static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping @Sendable (Timer) -> Void) -> Timer
}

extension Timer: TimerProtocol {}

public protocol LocationManagerWrapperDelegate: AnyObject {
    @MainActor func locationManager(_ wrapper: LocationManagerWrapper, didConfirmEntry regionId: String, locations: [CLLocation])
    @MainActor func locationManager(_ wrapper: LocationManagerWrapper, didConfirmExit regionId: String, locations: [CLLocation])
}

@preconcurrency
public final class LocationManagerWrapper: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManagerProtocol
    private let application: ApplicationProtocol
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var collectedLocations: [CLLocation] = []
    private var verificationTimer: Timer?
    private var currentRegionId: String?
    private var isEntryVerification: Bool = true

    public weak var delegate: LocationManagerWrapperDelegate?

    /// Duration for stay confirmation (default: 5 minutes)
    public var stayVerificationDuration: TimeInterval = 300
    /// Duration for exit confirmation (default: 2 minutes)
    public var exitVerificationDuration: TimeInterval = 120

    public init(
        locationManager: CLLocationManagerProtocol = CLLocationManager(),
        application: ApplicationProtocol = UIApplication.shared
    ) {
        self.locationManager = locationManager
        self.application = application
        super.init()
        self.locationManager.delegate = self
    }

    public func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    public func startMonitoring(for region: CLCircularRegion) {
        locationManager.startMonitoring(for: region)
    }

    public func stopMonitoring(for region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
    }

    public func syncMonitoredRegions(with workplaces: [(id: UUID, latitude: Double, longitude: Double, radius: Double)]) {
        // Remove old regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        // Add new regions
        for workplace in workplaces {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: workplace.latitude, longitude: workplace.longitude),
                radius: min(workplace.radius, locationManager.monitoredRegions.count < 20 ? CLLocationDistance.greatestFiniteMagnitude : 100),
                identifier: workplace.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    public nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            self.handleDidEnterRegion(region)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            self.handleDidExitRegion(region)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handleDidUpdateLocations(locations)
        }
    }

    // MARK: - Entry Handling

    @MainActor
    func handleDidEnterRegion(_ region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        startVerification(for: circularRegion.identifier, isEntry: true)
    }

    // MARK: - Exit Handling

    @MainActor
    func handleDidExitRegion(_ region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        startVerification(for: circularRegion.identifier, isEntry: false)
    }

    // MARK: - Location Updates

    @MainActor
    func handleDidUpdateLocations(_ locations: [CLLocation]) {
        collectedLocations.append(contentsOf: locations)
    }

    // MARK: - Verification Logic

    @MainActor
    private func startVerification(for regionId: String, isEntry: Bool) {
        // Cancel any existing verification
        cancelVerification()

        currentRegionId = regionId
        isEntryVerification = isEntry
        collectedLocations = []

        beginBackgroundTask()
        locationManager.startUpdatingLocation()

        let duration = isEntry ? stayVerificationDuration : exitVerificationDuration
        verificationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.completeVerification()
            }
        }
    }

    @MainActor
    func completeVerification() {
        guard let regionId = currentRegionId else { return }

        locationManager.stopUpdatingLocation()
        verificationTimer?.invalidate()
        verificationTimer = nil

        let locations = collectedLocations

        if isEntryVerification {
            // Check if user is still inside the region
            if isStayConfirmed(locations: locations, regionId: regionId) {
                delegate?.locationManager(self, didConfirmEntry: regionId, locations: locations)
            }
        } else {
            // Check if user has truly left
            if isExitConfirmed(locations: locations, regionId: regionId) {
                delegate?.locationManager(self, didConfirmExit: regionId, locations: locations)
            }
        }

        collectedLocations = []
        currentRegionId = nil
        endBackgroundTask()
    }

    @MainActor
    private func cancelVerification() {
        verificationTimer?.invalidate()
        verificationTimer = nil
        locationManager.stopUpdatingLocation()
        collectedLocations = []
        currentRegionId = nil
    }

    private func isStayConfirmed(locations: [CLLocation], regionId: String) -> Bool {
        guard !locations.isEmpty else { return false }

        // Find the region
        guard let region = locationManager.monitoredRegions.first(where: { $0.identifier == regionId }) as? CLCircularRegion else {
            return false
        }

        // Check if majority of recent locations are inside the region
        let recentLocations = Array(locations.suffix(10))
        let insideCount = recentLocations.filter { region.contains($0.coordinate) }.count
        return Double(insideCount) / Double(recentLocations.count) >= 0.7
    }

    private func isExitConfirmed(locations: [CLLocation], regionId: String) -> Bool {
        guard !locations.isEmpty else { return true }

        guard let region = locationManager.monitoredRegions.first(where: { $0.identifier == regionId }) as? CLCircularRegion else {
            return true
        }

        // Check if majority of recent locations are outside the region
        let recentLocations = Array(locations.suffix(10))
        let outsideCount = recentLocations.filter { !region.contains($0.coordinate) }.count
        return Double(outsideCount) / Double(recentLocations.count) >= 0.7
    }

    // MARK: - Background Task

    private func beginBackgroundTask() {
        if backgroundTaskID == .invalid {
            backgroundTaskID = application.beginBackgroundTask(withName: "LocationVerification") { [weak self] in
                Task { @MainActor in
                    self?.cancelVerification()
                    self?.endBackgroundTask()
                }
            }
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            application.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - Testing Support

    public func getLocations() -> [CLLocation] {
        collectedLocations
    }

    public func getCurrentRegionId() -> String? {
        currentRegionId
    }

    public func isVerifying() -> Bool {
        verificationTimer != nil
    }
}
