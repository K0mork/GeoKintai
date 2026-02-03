import CoreData

@MainActor
public final class WorkplaceRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    public func add(
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0,
        monitoringEnabled: Bool = true,
        createdAt: Date = Date()
    ) throws -> Workplace {
        let workplace = Workplace(context: context)
        workplace.id = UUID()
        workplace.name = name
        workplace.kLatitude = latitude
        workplace.kLongitude = longitude
        workplace.radius = radius
        workplace.monitoringEnabled = monitoringEnabled
        workplace.createdAt = createdAt
        try context.save()
        return workplace
    }

    public func fetchAll() throws -> [Workplace] {
        let request = Workplace.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(request)
    }

    public func delete(_ workplace: Workplace) throws {
        context.delete(workplace)
        if context.hasChanges {
            try context.save()
        }
    }
}
