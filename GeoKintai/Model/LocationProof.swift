import CoreData

@objc(LocationProof)
public class LocationProof: NSManagedObject, Identifiable {}

extension LocationProof {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationProof> {
        NSFetchRequest<LocationProof>(entityName: "LocationProof")
    }

    @NSManaged public var id: UUID
    @NSManaged public var recordId: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var accuracy: Double
    @NSManaged public var altitude: NSNumber?
    @NSManaged public var speed: NSNumber?
    @NSManaged public var reason: String
}
