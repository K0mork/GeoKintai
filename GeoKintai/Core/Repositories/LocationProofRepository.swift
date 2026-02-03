import CoreData
import CoreLocation

@MainActor
public final class LocationProofRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public enum ProofReason: String {
        case entryTrigger = "EntryTrigger"
        case stayCheck = "StayCheck"
        case exitCheck = "ExitCheck"
    }

    @discardableResult
    public func add(
        recordId: UUID,
        location: CLLocation,
        reason: ProofReason
    ) throws -> LocationProof {
        let proof = LocationProof(context: context)
        proof.id = UUID()
        proof.recordId = recordId
        proof.timestamp = location.timestamp
        proof.latitude = location.coordinate.latitude
        proof.longitude = location.coordinate.longitude
        proof.accuracy = location.horizontalAccuracy
        proof.altitude = location.altitude >= 0 ? NSNumber(value: location.altitude) : nil
        proof.speed = location.speed >= 0 ? NSNumber(value: location.speed) : nil
        proof.reason = reason.rawValue
        try context.save()
        return proof
    }

    public func addBatch(
        recordId: UUID,
        locations: [CLLocation],
        reason: ProofReason
    ) throws {
        for location in locations {
            let proof = LocationProof(context: context)
            proof.id = UUID()
            proof.recordId = recordId
            proof.timestamp = location.timestamp
            proof.latitude = location.coordinate.latitude
            proof.longitude = location.coordinate.longitude
            proof.accuracy = location.horizontalAccuracy
            proof.altitude = location.altitude >= 0 ? NSNumber(value: location.altitude) : nil
            proof.speed = location.speed >= 0 ? NSNumber(value: location.speed) : nil
            proof.reason = reason.rawValue
        }
        try context.save()
    }

    public func fetchProofs(for recordId: UUID) throws -> [LocationProof] {
        let request = LocationProof.fetchRequest()
        request.predicate = NSPredicate(format: "recordId == %@", recordId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try context.fetch(request)
    }
}
