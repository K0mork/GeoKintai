import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @StateObject private var permissionManager = LocationPermissionManager()

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Current Status")
                    Spacer()
                    Text(permissionManager.statusText)
                        .foregroundColor(permissionManager.statusColor)
                }
            } footer: {
                Text("GeoKintai requires 'Always' location permission to track attendance in the background.")
            }

            Section {
                Button {
                    permissionManager.requestPermission()
                } label: {
                    Label("Request Permission", systemImage: "location.fill")
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Location Permission")
    }
}

@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    var statusText: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "When In Use"
        case .authorizedAlways: return "Always ✓"
        @unknown default: return "Unknown"
        }
    }

    var statusColor: Color {
        switch authorizationStatus {
        case .authorizedAlways: return .green
        case .authorizedWhenInUse: return .orange
        case .denied, .restricted: return .red
        default: return .secondary
        }
    }

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

#Preview {
    NavigationStack {
        LocationPermissionView()
    }
}
