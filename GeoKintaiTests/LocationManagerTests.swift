// LocationManagerTests.swift
import XCTest
import CoreLocation
@testable import GeoKintai

final class MockLocationManager: CLLocationManagerProtocol {
    var delegate: CLLocationManagerDelegate?
    var didStartMonitoring = false
    var didStartUpdatingLocation = false
    func startMonitoring(for region: CLCircularRegion) {
        didStartMonitoring = true
    }
    func startUpdatingLocation() {
        didStartUpdatingLocation = true
    }
    func stopUpdatingLocation() {}
}

final class MockApplication: ApplicationProtocol {
    var didBeginBackgroundTask = false
    var didEndBackgroundTask = false
    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)? = nil) -> UIBackgroundTaskIdentifier {
        didBeginBackgroundTask = true
        return 1
    }
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        didEndBackgroundTask = true
    }
}

final class LocationManagerWrapperTests: XCTestCase {
    func testStartMonitoringForRegion() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        wrapper.startMonitoring(for: region)
        XCTAssertTrue(mockManager.didStartMonitoring)
    }

    func testDidEnterRegionTriggersBackgroundTaskAndStartUpdating() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        // Simulate didEnterRegion
        wrapper.handleDidEnterRegion(region)
        XCTAssertTrue(mockApp.didBeginBackgroundTask)
        XCTAssertTrue(mockManager.didStartUpdatingLocation)
    }

    func testThreadSafeLocationCollection() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        let locations = [CLLocation(latitude: 1, longitude: 1), CLLocation(latitude: 2, longitude: 2)]
        wrapper.handleDidUpdateLocations(locations)
        let collected = wrapper.getLocations()
        XCTAssertEqual(collected.count, 2)
        XCTAssertEqual(collected[0].coordinate.latitude, 1)
        XCTAssertEqual(collected[1].coordinate.latitude, 2)
    }
}
