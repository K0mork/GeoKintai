import CoreData

@MainActor
public struct PersistenceController {
    public static let shared = PersistenceController()
    public let container: NSPersistentContainer
    public var viewContext: NSManagedObjectContext { container.viewContext }

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GeoKintai")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
