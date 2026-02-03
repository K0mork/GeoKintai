import XCTest
import CoreData
@testable import GeoKintai

final class PersistenceControllerTests: XCTestCase {

    // MARK: - Container Loading Tests

    func testPersistentContainerLoads() async {
        let controller = await PersistenceController(inMemory: true)
        let container = await controller.container
        XCTAssertNotNil(container)
        let description = container.persistentStoreDescriptions.first
        XCTAssertNotNil(description)
        XCTAssertEqual(description?.type, NSInMemoryStoreType)
        XCTAssertEqual(description?.url?.path, "/dev/null")
    }

    func testViewContextIsAvailable() async {
        let controller = await PersistenceController(inMemory: true)
        let context = await controller.viewContext
        XCTAssertNotNil(context)
    }

    // MARK: - Entity Tests

    func testWorkplaceEntityExists() async {
        let controller = await PersistenceController(inMemory: true)
        let context = await controller.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Workplace", in: context)
        XCTAssertNotNil(entity)
    }

    func testAttendanceRecordEntityExists() async {
        let controller = await PersistenceController(inMemory: true)
        let context = await controller.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "AttendanceRecord", in: context)
        XCTAssertNotNil(entity)
    }

    func testLocationProofEntityExists() async {
        let controller = await PersistenceController(inMemory: true)
        let context = await controller.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "LocationProof", in: context)
        XCTAssertNotNil(entity)
    }

    // MARK: - In-Memory vs Persistent Tests

    func testInMemoryStoreDoesNotPersist() async {
        let controller1 = await PersistenceController(inMemory: true)
        let context1 = await controller1.viewContext

        await MainActor.run {
            let workplace = Workplace(context: context1)
            workplace.id = UUID()
            workplace.name = "Test"
            workplace.kLatitude = 35.0
            workplace.kLongitude = 139.0
            workplace.radius = 100
            workplace.monitoringEnabled = true
            try? context1.save()
        }

        // New in-memory controller should not have the data
        let controller2 = await PersistenceController(inMemory: true)
        let context2 = await controller2.viewContext

        let count = await MainActor.run {
            let request = Workplace.fetchRequest()
            return (try? context2.fetch(request).count) ?? 0
        }
        XCTAssertEqual(count, 0)
    }

    // MARK: - CRUD Operations Test

    func testBasicCRUDOperations() async {
        let controller = await PersistenceController(inMemory: true)
        let context = await controller.viewContext

        // Create
        let workplaceId = await MainActor.run { () -> UUID in
            let workplace = Workplace(context: context)
            workplace.id = UUID()
            workplace.name = "Test Office"
            workplace.kLatitude = 35.0
            workplace.kLongitude = 139.0
            workplace.radius = 100
            workplace.monitoringEnabled = true
            try? context.save()
            return workplace.id
        }

        // Read
        let fetchedName = await MainActor.run { () -> String? in
            let request = Workplace.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", workplaceId as CVarArg)
            return try? context.fetch(request).first?.name
        }
        XCTAssertEqual(fetchedName, "Test Office")

        // Update
        await MainActor.run {
            let request = Workplace.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", workplaceId as CVarArg)
            if let workplace = try? context.fetch(request).first {
                workplace.name = "Updated Office"
                try? context.save()
            }
        }

        let updatedName = await MainActor.run { () -> String? in
            let request = Workplace.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", workplaceId as CVarArg)
            return try? context.fetch(request).first?.name
        }
        XCTAssertEqual(updatedName, "Updated Office")

        // Delete
        await MainActor.run {
            let request = Workplace.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", workplaceId as CVarArg)
            if let workplace = try? context.fetch(request).first {
                context.delete(workplace)
                try? context.save()
            }
        }

        let count = await MainActor.run { () -> Int in
            let request = Workplace.fetchRequest()
            return (try? context.fetch(request).count) ?? -1
        }
        XCTAssertEqual(count, 0)
    }
}
