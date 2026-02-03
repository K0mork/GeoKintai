import SwiftUI

struct StatusView: View {
    @ObservedObject var viewModel: StatusViewModel
    
    var body: some View {
        List {
            Section(header: Text(viewModel.sectionTitle), footer: Text(viewModel.sectionDescription)) {
                Text(viewModel.statusText)
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            Section(header: Text("Map")) {
                Text("[Map Placeholder]")
                    .foregroundColor(.secondary)
            }
            Section(header: Text("Actions")) {
                Button(viewModel.actionTitle) {
                    do {
                        try viewModel.performPrimaryAction()
                    } catch {
                        viewModel.clearError()
                    }
                }
                .font(.headline)
                .foregroundColor(.accentColor)
            }
        }
        .listStyle(.insetGrouped)
    }
}
