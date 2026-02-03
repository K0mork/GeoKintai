// LocationManagerTests.swift
import XCTest
import CoreLocation
@testable import GeoKintai

final class MockLocationManager: CLLocationManagerProtocol {
    var delegate: CLLocationManagerDelegate?
    var didStartMonitoring = false
    var didStopMonitoring = false
    var didStartUpdatingLocation = false
    var didStopUpdatingLocation = false
    var didRequestAlwaysAuth = false
    var monitoredRegions: Set<CLRegion> = []

    func startMonitoring(for region: CLRegion) {
        didStartMonitoring = true
        monitoredRegions.insert(region)
    }
    func stopMonitoring(for region: CLRegion) {
        didStopMonitoring = true
        monitoredRegions.remove(region)
    }
    func startUpdatingLocation() {
        didStartUpdatingLocation = true
    }
    func stopUpdatingLocation() {
        didStopUpdatingLocation = true
    }
    func requestAlwaysAuthorization() {
        didRequestAlwaysAuth = true
    }
}

final class MockApplication: ApplicationProtocol {
    var didBeginBackgroundTask = false
    var didEndBackgroundTask = false
    var backgroundTaskCount = 0

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (@MainActor @Sendable () -> Void)? = nil) -> UIBackgroundTaskIdentifier {
        didBeginBackgroundTask = true
        backgroundTaskCount += 1
        return UIBackgroundTaskIdentifier(rawValue: backgroundTaskCount)
    }
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        didEndBackgroundTask = true
    }
}

final class MockLocationManagerDelegate: LocationManagerWrapperDelegate {
    var confirmedEntryRegionId: String?
    var confirmedEntryLocations: [CLLocation] = []
    var confirmedExitRegionId: String?
    var confirmedExitLocations: [CLLocation] = []
    var entryCallCount = 0
    var exitCallCount = 0

    func locationManager(_ wrapper: LocationManagerWrapper, didConfirmEntry regionId: String, locations: [CLLocation]) {
        confirmedEntryRegionId = regionId
        confirmedEntryLocations = locations
        entryCallCount += 1
    }

    func locationManager(_ wrapper: LocationManagerWrapper, didConfirmExit regionId: String, locations: [CLLocation]) {
        confirmedExitRegionId = regionId
        confirmedExitLocations = locations
        exitCallCount += 1
    }
}

final class LocationManagerWrapperTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitializationSetsDelegate() {
        let mockManager = MockLocationManager()
        _ = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        XCTAssertNotNil(mockManager.delegate)
    }

    // MARK: - Authorization Tests

    func testRequestAuthorization() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        wrapper.requestAuthorization()
        XCTAssertTrue(mockManager.didRequestAlwaysAuth)
    }

    // MARK: - Region Monitoring Tests

    func testStartMonitoringForRegion() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        wrapper.startMonitoring(for: region)
        XCTAssertTrue(mockManager.didStartMonitoring)
    }

    func testStopMonitoringForRegion() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        wrapper.stopMonitoring(for: region)
        XCTAssertTrue(mockManager.didStopMonitoring)
    }

    func testSyncMonitoredRegions() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())

        let workplaces = [
            (id: UUID(), latitude: 35.0, longitude: 139.0, radius: 100.0),
            (id: UUID(), latitude: 36.0, longitude: 140.0, radius: 150.0)
        ]
        wrapper.syncMonitoredRegions(with: workplaces)

        XCTAssertEqual(mockManager.monitoredRegions.count, 2)
    }

    func testSyncMonitoredRegionsRemovesOldRegions() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())

        // Add initial regions
        let oldRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "old")
        mockManager.monitoredRegions.insert(oldRegion)

        // Sync with new workplaces
        let workplaces = [(id: UUID(), latitude: 35.0, longitude: 139.0, radius: 100.0)]
        wrapper.syncMonitoredRegions(with: workplaces)

        // Old region should be removed
        XCTAssertTrue(mockManager.didStopMonitoring)
        XCTAssertEqual(mockManager.monitoredRegions.count, 1)
    }

    func testSyncMonitoredRegionsWithEmptyList() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())

        wrapper.syncMonitoredRegions(with: [])

        XCTAssertTrue(mockManager.monitoredRegions.isEmpty)
    }

    // MARK: - Entry Region Tests

    @MainActor
    func testDidEnterRegionTriggersBackgroundTaskAndStartUpdating() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidEnterRegion(region)

        XCTAssertTrue(mockApp.didBeginBackgroundTask)
        XCTAssertTrue(mockManager.didStartUpdatingLocation)
        XCTAssertTrue(wrapper.isVerifying())
        XCTAssertEqual(wrapper.getCurrentRegionId(), "test")
    }

    @MainActor
    func testDidEnterRegionIgnoresNonCircularRegion() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)

        // Create a non-circular region (beacon region)
        let beaconRegion = CLBeaconRegion(uuid: UUID(), identifier: "beacon")
        wrapper.handleDidEnterRegion(beaconRegion)

        XCTAssertFalse(mockApp.didBeginBackgroundTask)
        XCTAssertFalse(wrapper.isVerifying())
    }

    // MARK: - Exit Region Tests

    @MainActor
    func testDidExitRegionTriggersVerification() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100, identifier: "test")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidExitRegion(region)

        XCTAssertTrue(mockApp.didBeginBackgroundTask)
        XCTAssertTrue(mockManager.didStartUpdatingLocation)
        XCTAssertTrue(wrapper.isVerifying())
    }

    // MARK: - Location Collection Tests

    @MainActor
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

    @MainActor
    func testLocationCollectionAccumulates() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())

        wrapper.handleDidUpdateLocations([CLLocation(latitude: 1, longitude: 1)])
        wrapper.handleDidUpdateLocations([CLLocation(latitude: 2, longitude: 2)])
        wrapper.handleDidUpdateLocations([CLLocation(latitude: 3, longitude: 3)])

        XCTAssertEqual(wrapper.getLocations().count, 3)
    }

    // MARK: - Verification Completion Tests

    @MainActor
    func testCompleteVerificationCallsDelegateOnStayConfirm() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        // Simulate entry
        wrapper.handleDidEnterRegion(region)

        // Add locations inside the region (need 70% inside)
        let insideLocations = (0..<10).map { _ in
            CLLocation(latitude: 35.0, longitude: 139.0)
        }
        wrapper.handleDidUpdateLocations(insideLocations)

        // Complete verification
        wrapper.completeVerification()

        XCTAssertEqual(mockDelegate.confirmedEntryRegionId, "workplace1")
        XCTAssertEqual(mockDelegate.confirmedEntryLocations.count, 10)
        XCTAssertTrue(mockManager.didStopUpdatingLocation)
        XCTAssertTrue(mockApp.didEndBackgroundTask)
    }

    @MainActor
    func testCompleteVerificationDoesNotCallDelegateOnFalseAlarm() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        // Simulate entry
        wrapper.handleDidEnterRegion(region)

        // Add locations OUTSIDE the region (false alarm - user passed through)
        let outsideLocations = (0..<10).map { _ in
            CLLocation(latitude: 40.0, longitude: 145.0) // Far away
        }
        wrapper.handleDidUpdateLocations(outsideLocations)

        // Complete verification
        wrapper.completeVerification()

        // Delegate should NOT be called for false alarm
        XCTAssertNil(mockDelegate.confirmedEntryRegionId)
        XCTAssertEqual(mockDelegate.entryCallCount, 0)
    }

    @MainActor
    func testCompleteVerificationCallsDelegateOnExitConfirm() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        // Simulate exit
        wrapper.handleDidExitRegion(region)

        // Add locations OUTSIDE the region (user really left)
        let outsideLocations = (0..<10).map { _ in
            CLLocation(latitude: 40.0, longitude: 145.0)
        }
        wrapper.handleDidUpdateLocations(outsideLocations)

        // Complete verification
        wrapper.completeVerification()

        XCTAssertEqual(mockDelegate.confirmedExitRegionId, "workplace1")
        XCTAssertEqual(mockDelegate.exitCallCount, 1)
    }

    @MainActor
    func testCompleteVerificationDoesNotConfirmExitOnGpsDrift() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        // Simulate exit
        wrapper.handleDidExitRegion(region)

        // Add locations INSIDE the region (GPS drift - user still there)
        let insideLocations = (0..<10).map { _ in
            CLLocation(latitude: 35.0, longitude: 139.0)
        }
        wrapper.handleDidUpdateLocations(insideLocations)

        // Complete verification
        wrapper.completeVerification()

        // Exit should NOT be confirmed (GPS drift)
        XCTAssertNil(mockDelegate.confirmedExitRegionId)
        XCTAssertEqual(mockDelegate.exitCallCount, 0)
    }

    @MainActor
    func testCompleteVerificationConfirmsEntryAtThreshold() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidEnterRegion(region)

        let insideLocations = (0..<7).map { _ in
            CLLocation(latitude: 35.0, longitude: 139.0)
        }
        let outsideLocations = (0..<3).map { _ in
            CLLocation(latitude: 40.0, longitude: 145.0)
        }
        wrapper.handleDidUpdateLocations(insideLocations + outsideLocations)

        wrapper.completeVerification()

        XCTAssertEqual(mockDelegate.confirmedEntryRegionId, "workplace1")
        XCTAssertEqual(mockDelegate.entryCallCount, 1)
    }

    @MainActor
    func testCompleteVerificationDoesNotConfirmEntryBelowThreshold() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "workplace1")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidEnterRegion(region)

        let insideLocations = (0..<6).map { _ in
            CLLocation(latitude: 35.0, longitude: 139.0)
        }
        let outsideLocations = (0..<4).map { _ in
            CLLocation(latitude: 40.0, longitude: 145.0)
        }
        wrapper.handleDidUpdateLocations(insideLocations + outsideLocations)

        wrapper.completeVerification()

        XCTAssertNil(mockDelegate.confirmedEntryRegionId)
        XCTAssertEqual(mockDelegate.entryCallCount, 0)
    }

    // MARK: - State Tests

    @MainActor
    func testIsVerifyingReturnsFalseInitially() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        XCTAssertFalse(wrapper.isVerifying())
    }

    @MainActor
    func testGetCurrentRegionIdReturnsNilInitially() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        XCTAssertNil(wrapper.getCurrentRegionId())
    }

    @MainActor
    func testGetLocationsReturnsEmptyArrayInitially() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        XCTAssertTrue(wrapper.getLocations().isEmpty)
    }

    @MainActor
    func testCompleteVerificationClearsState() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "test")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidEnterRegion(region)
        wrapper.handleDidUpdateLocations([CLLocation(latitude: 35.0, longitude: 139.0)])
        wrapper.completeVerification()

        XCTAssertFalse(wrapper.isVerifying())
        XCTAssertNil(wrapper.getCurrentRegionId())
        XCTAssertTrue(wrapper.getLocations().isEmpty)
    }

    // MARK: - Verification Duration Tests

    @MainActor
    func testDefaultVerificationDurations() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        XCTAssertEqual(wrapper.stayVerificationDuration, 300) // 5 minutes
        XCTAssertEqual(wrapper.exitVerificationDuration, 120) // 2 minutes
    }

    @MainActor
    func testCustomVerificationDurations() {
        let mockManager = MockLocationManager()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        wrapper.stayVerificationDuration = 600
        wrapper.exitVerificationDuration = 180
        XCTAssertEqual(wrapper.stayVerificationDuration, 600)
        XCTAssertEqual(wrapper.exitVerificationDuration, 180)
    }

    // MARK: - Edge Cases

    @MainActor
    func testCompleteVerificationWithNoLocations() {
        let mockManager = MockLocationManager()
        let mockDelegate = MockLocationManagerDelegate()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: MockApplication())
        wrapper.delegate = mockDelegate

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "test")
        mockManager.monitoredRegions.insert(region)

        wrapper.handleDidEnterRegion(region)
        // No locations added
        wrapper.completeVerification()

        // Should not confirm with no locations
        XCTAssertNil(mockDelegate.confirmedEntryRegionId)
    }

    @MainActor
    func testMultipleEntryCancelsExistingVerification() {
        let mockManager = MockLocationManager()
        let mockApp = MockApplication()
        let wrapper = LocationManagerWrapper(locationManager: mockManager, application: mockApp)

        let region1 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0), radius: 100, identifier: "region1")
        let region2 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 36.0, longitude: 140.0), radius: 100, identifier: "region2")
        mockManager.monitoredRegions.insert(region1)
        mockManager.monitoredRegions.insert(region2)

        wrapper.handleDidEnterRegion(region1)
        XCTAssertEqual(wrapper.getCurrentRegionId(), "region1")

        wrapper.handleDidEnterRegion(region2)
        XCTAssertEqual(wrapper.getCurrentRegionId(), "region2")
    }
}
