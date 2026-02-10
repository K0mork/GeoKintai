import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "dot.radiowaves.left.and.right")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
