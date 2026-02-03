import SwiftUI

struct SettingsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Workplaces")) {
                    NavigationLink {
                        WorkplaceListView()
                    } label: {
                        Label("Manage Workplaces", systemImage: "building.2")
                    }
                }

                Section(header: Text("Location")) {
                    NavigationLink {
                        LocationPermissionView()
                    } label: {
                        Label("Location Permission", systemImage: "location")
                    }
                }

                Section(header: Text("About")) {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTab()
}
