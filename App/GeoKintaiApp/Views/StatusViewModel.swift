import Foundation
import MapKit
import GeoKintaiCore

@MainActor
struct StatusViewModel {
    let selectedWorkplace: Workplace?
    let selectedWorkplaceName: String
    let permissionGuidance: PermissionGuidance
    let shouldRunAutoRecording: Bool
    let openRecord: AttendanceRecord?
    let monitoredWorkplaceCount: Int
    let lastExport: ExportPayload?

    init(store: AppStore) {
        selectedWorkplace = store.workplaces.first(where: { $0.id == store.selectedWorkplaceId })
        selectedWorkplaceName = selectedWorkplace?.name ?? "未選択"
        permissionGuidance = store.permissionDecision.guidance
        shouldRunAutoRecording = store.permissionDecision.shouldRunAutoRecording
        openRecord = store.attendanceRecords.first(where: { $0.exitTime == nil })
        monitoredWorkplaceCount = store.monitoredWorkplaceIds.count
        lastExport = store.lastExport
    }

    var hasPermissionWarning: Bool {
        !shouldRunAutoRecording
    }

    var canOpenSettings: Bool {
        permissionGuidance == .openSettings
    }

    var mapRegion: MKCoordinateRegion? {
        guard let selectedWorkplace else {
            return nil
        }

        let delta = max(0.005, selectedWorkplace.radius / 10_000)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: selectedWorkplace.latitude,
                longitude: selectedWorkplace.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )
    }

    var exportPreviewLines: [String] {
        guard let lastExport else {
            return []
        }
        return lastExport.content
            .split(separator: "\n")
            .prefix(5)
            .map(String.init)
    }
}
