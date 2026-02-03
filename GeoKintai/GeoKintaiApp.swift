import SwiftUI

@main
struct GeoKintaiApp: App {
    let persistenceController = PersistenceController.shared
    @State private var coordinator = AppCoordinator.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    coordinator.start()
                }
        }
    }
}
