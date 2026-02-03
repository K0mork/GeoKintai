import CoreData

@MainActor
public final class AttendanceRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    public func checkIn(
        workplaceId: UUID,
        entryTime: Date = Date(),
        isManual: Bool = false,
        note: String? = nil
    ) throws -> AttendanceRecord {
        let record = AttendanceRecord(context: context)
        record.id = UUID()
        record.workplaceId = workplaceId
        record.entryTime = entryTime
        record.exitTime = nil
        record.isManual = isManual
        record.note = note
        try context.save()
        return record
    }

    public func checkOut(
        _ record: AttendanceRecord,
        exitTime: Date = Date()
    ) throws {
        record.exitTime = exitTime
        try context.save()
    }

    public func fetchRecords(for workplaceId: UUID) throws -> [AttendanceRecord] {
        let request = AttendanceRecord.fetchRequest()
        request.predicate = NSPredicate(format: "workplaceId == %@", workplaceId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "entryTime", ascending: true)]
        return try context.fetch(request)
    }
}
