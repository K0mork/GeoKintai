import Foundation
import CoreData

@MainActor
public final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [AttendanceRecord] = []
    @Published private(set) var groupedRecords: [Date: [AttendanceRecord]] = [:]
    @Published private(set) var errorMessage: String?

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
        fetchRecords()
    }

    public func fetchRecords() {
        do {
            let request = AttendanceRecord.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "entryTime", ascending: false)]
            records = try context.fetch(request)
            groupRecordsByDate()
            errorMessage = nil
        } catch {
            records = []
            groupedRecords = [:]
            errorMessage = error.localizedDescription
        }
    }

    private func groupRecordsByDate() {
        groupedRecords = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.entryTime)
        }
    }

    public var sortedDates: [Date] {
        groupedRecords.keys.sorted(by: >)
    }

    public func records(for date: Date) -> [AttendanceRecord] {
        groupedRecords[date] ?? []
    }

    public var hasRecords: Bool {
        !records.isEmpty
    }

    public var totalRecordCount: Int {
        records.count
    }

    public func deleteRecord(_ record: AttendanceRecord) {
        context.delete(record)
        do {
            try context.save()
            fetchRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
