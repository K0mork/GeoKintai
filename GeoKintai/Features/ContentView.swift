import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            StatusTab()
                .tabItem {
                    Label("Status", systemImage: "clock.badge.checkmark")
                }

            HistoryTab()
                .tabItem {
                    Label("History", systemImage: "list.bullet.rectangle")
                }

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    return ContentView()
        .environment(\.managedObjectContext, controller.viewContext)
}
