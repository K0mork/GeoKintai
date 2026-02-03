import Foundation
import CoreData

@MainActor
protocol HistoryRecordStore {
    func fetchRecords() throws -> [AttendanceRecord]
    func delete(_ record: AttendanceRecord) throws
}

@MainActor
final class CoreDataHistoryRecordStore: HistoryRecordStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchRecords() throws -> [AttendanceRecord] {
        let request = AttendanceRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "entryTime", ascending: false)]
        return try context.fetch(request)
    }

    func delete(_ record: AttendanceRecord) throws {
        context.delete(record)
        try context.save()
    }
}

@MainActor
public final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [AttendanceRecord] = []
    @Published private(set) var groupedRecords: [Date: [AttendanceRecord]] = [:]
    @Published private(set) var errorMessage: String?

    private let store: HistoryRecordStore

    public init(context: NSManagedObjectContext) {
        self.store = CoreDataHistoryRecordStore(context: context)
        fetchRecords()
    }

    init(store: HistoryRecordStore) {
        self.store = store
        fetchRecords()
    }

    public func fetchRecords() {
        do {
            records = try store.fetchRecords()
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
        do {
            try store.delete(record)
            fetchRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
