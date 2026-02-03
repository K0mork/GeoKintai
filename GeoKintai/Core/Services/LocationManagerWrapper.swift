// LocationManagerWrapper.swift
// Minimal stub for TDD
import Foundation
import CoreLocation
import UIKit

public protocol CLLocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    func startMonitoring(for region: CLRegion)
    func startUpdatingLocation()
    func stopUpdatingLocation()
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

@preconcurrency
public final class LocationManagerWrapper: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManagerProtocol
    private let application: ApplicationProtocol
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var locations: [CLLocation] = []

    public init(
        locationManager: CLLocationManagerProtocol = CLLocationManager(),
        application: ApplicationProtocol = UIApplication.shared
    ) {
        self.locationManager = locationManager
        self.application = application
        super.init()
        self.locationManager.delegate = self
    }

    public func startMonitoring(for region: CLCircularRegion) {
        locationManager.startMonitoring(for: region)
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            self.handleDidEnterRegion(region)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handleDidUpdateLocations(locations)
        }
    }

    @MainActor
    func handleDidEnterRegion(_ region: CLRegion) {
        guard region is CLCircularRegion else { return }
        beginBackgroundTask()
        locationManager.startUpdatingLocation()
    }

    @MainActor
    func handleDidUpdateLocations(_ locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }

    private func beginBackgroundTask() {
        if backgroundTaskID == .invalid {
            backgroundTaskID = application.beginBackgroundTask(withName: "LocationUpdate") { [weak self] in
                self?.endBackgroundTask()
            }
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            application.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    public func getLocations() -> [CLLocation] {
        locations
    }
}
