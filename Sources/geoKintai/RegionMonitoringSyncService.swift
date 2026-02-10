import Foundation

public struct MonitoredRegion: Equatable {
    public let workplaceId: UUID
    public let latitude: Double
    public let longitude: Double
    public let radius: Double

    public init(workplaceId: UUID, latitude: Double, longitude: Double, radius: Double) {
        self.workplaceId = workplaceId
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}

public protocol RegionMonitor: AnyObject {
    func startMonitoring(region: MonitoredRegion)
    func stopMonitoring(workplaceId: UUID)
    func monitoredWorkplaceIds() -> Set<UUID>
    func monitoredRegions() -> [UUID: MonitoredRegion]
}

public final class InMemoryRegionMonitor: RegionMonitor {
    private var regionsByWorkplaceId: [UUID: MonitoredRegion]

    public init(initialRegions: [MonitoredRegion] = []) {
        self.regionsByWorkplaceId = Dictionary(uniqueKeysWithValues: initialRegions.map { ($0.workplaceId, $0) })
    }

    public func startMonitoring(region: MonitoredRegion) {
        regionsByWorkplaceId[region.workplaceId] = region
    }

    public func stopMonitoring(workplaceId: UUID) {
        regionsByWorkplaceId.removeValue(forKey: workplaceId)
    }

    public func monitoredWorkplaceIds() -> Set<UUID> {
        Set(regionsByWorkplaceId.keys)
    }

    public func monitoredRegions() -> [UUID: MonitoredRegion] {
        regionsByWorkplaceId
    }
}

public struct RegionMonitoringSyncResult: Equatable {
    public let monitoredWorkplaceIds: Set<UUID>
    public let changedWorkplaceIds: Set<UUID>

    public init(monitoredWorkplaceIds: Set<UUID>, changedWorkplaceIds: Set<UUID>) {
        self.monitoredWorkplaceIds = monitoredWorkplaceIds
        self.changedWorkplaceIds = changedWorkplaceIds
    }
}

public final class RegionMonitoringSyncService {
    private let regionMonitor: RegionMonitor

    public init(regionMonitor: RegionMonitor) {
        self.regionMonitor = regionMonitor
    }

    @discardableResult
    public func sync(workplaces: [Workplace], allowMonitoring: Bool) -> RegionMonitoringSyncResult {
        let targetRegions: [MonitoredRegion]
        if allowMonitoring {
            targetRegions = workplaces
                .filter { $0.monitoringEnabled }
                .map {
                    MonitoredRegion(
                        workplaceId: $0.id,
                        latitude: $0.latitude,
                        longitude: $0.longitude,
                        radius: $0.radius
                    )
                }
        } else {
            targetRegions = []
        }

        let targetRegionMap = Dictionary(uniqueKeysWithValues: targetRegions.map { ($0.workplaceId, $0) })
        let targetIds = Set(targetRegions.map(\.workplaceId))
        let currentRegions = regionMonitor.monitoredRegions()
        let currentIds = Set(currentRegions.keys)

        for id in currentIds where !targetIds.contains(id) {
            regionMonitor.stopMonitoring(workplaceId: id)
        }

        var changedWorkplaceIds: Set<UUID> = []
        for (workplaceId, targetRegion) in targetRegionMap {
            if let currentRegion = currentRegions[workplaceId], currentRegion == targetRegion {
                continue
            }

            if currentRegions[workplaceId] != nil {
                regionMonitor.stopMonitoring(workplaceId: workplaceId)
            }
            regionMonitor.startMonitoring(region: targetRegion)
            changedWorkplaceIds.insert(workplaceId)
        }

        return RegionMonitoringSyncResult(
            monitoredWorkplaceIds: regionMonitor.monitoredWorkplaceIds(),
            changedWorkplaceIds: changedWorkplaceIds
        )
    }
}
