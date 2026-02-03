import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: StatusViewModel

    init(viewModel: @autoclosure @escaping () -> StatusViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    init() {
        let controller = PersistenceController.shared
        let repository = AttendanceRepository(context: controller.viewContext)
        self.init(viewModel: StatusViewModel(repository: repository, workplaceId: UUID()))
    }

    var body: some View {
        StatusView(viewModel: viewModel)
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let repository = AttendanceRepository(context: controller.viewContext)
    return ContentView(viewModel: StatusViewModel(repository: repository, workplaceId: UUID()))
        .environment(\.managedObjectContext, controller.viewContext)
}
