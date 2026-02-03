import SwiftUI

struct StatusTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workplace.createdAt, ascending: true)],
        predicate: NSPredicate(format: "monitoringEnabled == YES"),
        animation: .default
    )
    private var workplaces: FetchedResults<Workplace>

    var body: some View {
        NavigationStack {
            Group {
                if let workplace = workplaces.first {
                    StatusViewContainer(workplace: workplace)
                } else {
                    NoWorkplaceView()
                }
            }
            .navigationTitle("Status")
        }
    }
}

private struct StatusViewContainer: View {
    let workplace: Workplace
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: StatusViewModel

    init(workplace: Workplace) {
        self.workplace = workplace
        let repository = AttendanceRepository(context: workplace.managedObjectContext!)
        _viewModel = StateObject(wrappedValue: StatusViewModel(repository: repository, workplaceId: workplace.id))
    }

    var body: some View {
        StatusView(viewModel: viewModel)
    }
}

private struct NoWorkplaceView: View {
    var body: some View {
        List {
            Section {
                Text("No workplace registered")
                    .foregroundColor(.secondary)
            } footer: {
                Text("Go to Settings to add a workplace.")
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    return StatusTab()
        .environment(\.managedObjectContext, controller.viewContext)
}
