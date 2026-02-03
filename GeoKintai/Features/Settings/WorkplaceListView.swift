import SwiftUI

struct WorkplaceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workplace.createdAt, ascending: true)],
        animation: .default
    )
    private var workplaces: FetchedResults<Workplace>

    @State private var showingAddSheet = false

    var body: some View {
        List {
            if workplaces.isEmpty {
                Section {
                    Text("No workplaces registered")
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Tap + to add your first workplace.")
                }
            } else {
                ForEach(workplaces) { workplace in
                    NavigationLink {
                        WorkplaceEditView(workplace: workplace)
                    } label: {
                        WorkplaceRowView(workplace: workplace)
                    }
                }
                .onDelete(perform: deleteWorkplaces)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workplaces")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                WorkplaceEditView(workplace: nil)
            }
        }
    }

    private func deleteWorkplaces(offsets: IndexSet) {
        withAnimation {
            offsets.map { workplaces[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct WorkplaceRowView: View {
    let workplace: Workplace

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workplace.name)
                    .font(.headline)
                Spacer()
                if workplace.monitoringEnabled {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            Text("Radius: \(Int(workplace.radius))m")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    return NavigationStack {
        WorkplaceListView()
    }
    .environment(\.managedObjectContext, controller.viewContext)
}
