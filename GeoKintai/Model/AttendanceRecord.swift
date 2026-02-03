import CoreData

@objc(AttendanceRecord)
public class AttendanceRecord: NSManagedObject {}

extension AttendanceRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AttendanceRecord> {
        NSFetchRequest<AttendanceRecord>(entityName: "AttendanceRecord")
    }

    @NSManaged public var id: UUID
    @NSManaged public var workplaceId: UUID
    @NSManaged public var entryTime: Date
    @NSManaged public var exitTime: Date?
    @NSManaged public var isManual: Bool
    @NSManaged public var note: String?
}
