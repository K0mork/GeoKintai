import Foundation
import Testing
@testable import geoKintai

@Suite("RegionMonitoringSyncServiceTests")
struct RegionMonitoringSyncServiceTests {
    @Test("P3-011: test_regionSync_whenAllowMonitoringOnLaunch_startsEnabledWorkplaces")
    func test_regionSync_whenAllowMonitoringOnLaunch_startsEnabledWorkplaces() {
        let workplaceA = Workplace(
            id: UUID(uuidString: "AAAA0000-1111-1111-1111-111111111111")!,
            name: "A",
            latitude: 35,
            longitude: 139,
            radius: 100,
            monitoringEnabled: true
        )
        let workplaceB = Workplace(
            id: UUID(uuidString: "BBBB0000-2222-2222-2222-222222222222")!,
            name: "B",
            latitude: 34,
            longitude: 135,
            radius: 120,
            monitoringEnabled: false
        )
        let monitor = InMemoryRegionMonitor()
        let service = RegionMonitoringSyncService(regionMonitor: monitor)

        let result = service.sync(workplaces: [workplaceA, workplaceB], allowMonitoring: true)

        #expect(result.monitoredWorkplaceIds == [workplaceA.id])
        #expect(result.changedWorkplaceIds == [workplaceA.id])
    }

    @Test("P3-012: test_regionSync_whenWorkplaceUpdated_resyncsMonitoredSet")
    func test_regionSync_whenWorkplaceUpdated_resyncsMonitoredSet() {
        var workplace = Workplace(
            id: UUID(uuidString: "CCCC0000-3333-3333-3333-333333333333")!,
            name: "C",
            latitude: 43,
            longitude: 141,
            radius: 100,
            monitoringEnabled: true
        )
        let monitor = InMemoryRegionMonitor()
        let service = RegionMonitoringSyncService(regionMonitor: monitor)

        _ = service.sync(workplaces: [workplace], allowMonitoring: true)
        workplace.monitoringEnabled = false
        let result = service.sync(workplaces: [workplace], allowMonitoring: true)

        #expect(result.monitoredWorkplaceIds.isEmpty)
        #expect(result.changedWorkplaceIds.isEmpty)
    }

    @Test("P3-012: test_regionSync_whenWorkplaceCoordinateChanged_restartsMonitoringWithLatestRegion")
    func test_regionSync_whenWorkplaceCoordinateChanged_restartsMonitoringWithLatestRegion() {
        var workplace = Workplace(
            id: UUID(uuidString: "EEEE0000-5555-5555-5555-555555555555")!,
            name: "E",
            latitude: 35,
            longitude: 139,
            radius: 100,
            monitoringEnabled: true
        )
        let monitor = InMemoryRegionMonitor()
        let service = RegionMonitoringSyncService(regionMonitor: monitor)

        _ = service.sync(workplaces: [workplace], allowMonitoring: true)

        workplace.latitude = 35.5
        workplace.longitude = 139.5
        workplace.radius = 180
        let result = service.sync(workplaces: [workplace], allowMonitoring: true)

        let monitored = monitor.monitoredRegions()[workplace.id]
        #expect(result.monitoredWorkplaceIds == [workplace.id])
        #expect(result.changedWorkplaceIds == [workplace.id])
        #expect(monitored?.latitude == 35.5)
        #expect(monitored?.longitude == 139.5)
        #expect(monitored?.radius == 180)
    }

    @Test("P3-022: test_regionSync_whenPermissionDowngraded_stopsAllMonitoring")
    func test_regionSync_whenPermissionDowngraded_stopsAllMonitoring() {
        let workplace = Workplace(
            id: UUID(uuidString: "DDDD0000-4444-4444-4444-444444444444")!,
            name: "D",
            latitude: 35,
            longitude: 139,
            radius: 100,
            monitoringEnabled: true
        )
        let monitor = InMemoryRegionMonitor()
        let service = RegionMonitoringSyncService(regionMonitor: monitor)

        _ = service.sync(workplaces: [workplace], allowMonitoring: true)
        let result = service.sync(workplaces: [workplace], allowMonitoring: false)

        #expect(result.monitoredWorkplaceIds.isEmpty)
        #expect(result.changedWorkplaceIds.isEmpty)
    }
}
