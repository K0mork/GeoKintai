import SwiftUI
import GeoKintaiCore

@main
struct GeoKintaiApp: App {
    @StateObject private var store: AppStore

    init() {
        let locationMonitor = CoreLocationRegionMonitor()
        let syncService = RegionMonitoringSyncService(regionMonitor: locationMonitor)
        _store = StateObject(
            wrappedValue: AppStore(
                regionMonitoringSyncService: syncService,
                backgroundLocationClient: locationMonitor
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
