import CoreData

@objc(Workplace)
public class Workplace: NSManagedObject, Identifiable {}

extension Workplace {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workplace> {
        NSFetchRequest<Workplace>(entityName: "Workplace")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var kLatitude: Double
    @NSManaged public var kLongitude: Double
    @NSManaged public var radius: Double
    @NSManaged public var monitoringEnabled: Bool
    @NSManaged public var createdAt: Date?
}
