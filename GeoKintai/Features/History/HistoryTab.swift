import SwiftUI

struct HistoryTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AttendanceRecord.entryTime, ascending: false)],
        animation: .default
    )
    private var records: FetchedResults<AttendanceRecord>

    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Section {
                        Text("No attendance records yet")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(groupedRecords.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date, style: .date)) {
                            ForEach(groupedRecords[date] ?? []) { record in
                                NavigationLink {
                                    HistoryDetailView(record: record)
                                } label: {
                                    HistoryRowView(record: record)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
        }
    }

    private var groupedRecords: [Date: [AttendanceRecord]] {
        Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.entryTime)
        }
    }
}

struct HistoryRowView: View {
    let record: AttendanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workplaceName)
                .font(.headline)
            HStack {
                Text(record.entryTime, style: .time)
                Text("–")
                if let exitTime = record.exitTime {
                    Text(exitTime, style: .time)
                } else {
                    Text("In Progress")
                        .foregroundColor(.green)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var workplaceName: String {
        guard let context = record.managedObjectContext else { return "Unknown" }
        let request = Workplace.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.workplaceId as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first?.name) ?? "Unknown"
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    return HistoryTab()
        .environment(\.managedObjectContext, controller.viewContext)
}
