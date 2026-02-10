import Foundation
import Testing
@testable import geoKintai

@Suite("PersistenceControllerTests")
struct PersistenceControllerTests {
    @Test("P1-015: test_persistenceController_whenStoreData_keepsRepositoriesUsable")
    func test_persistenceController_whenStoreData_keepsRepositoriesUsable() {
        let controller = PersistenceController()
        let workplaceId = UUID(uuidString: "ABABABAB-ABAB-ABAB-ABAB-ABABABABABAB")!
        let workplace = Workplace(
            id: workplaceId,
            name: "Nagoya Office",
            latitude: 35.1815,
            longitude: 136.9066,
            radius: 100,
            monitoringEnabled: true
        )

        controller.workplaces.save(workplace)
        let record = controller.attendance.createOpenRecord(
            workplaceId: workplaceId,
            entryTime: Date(timeIntervalSince1970: 1_700_200_000)
        )

        #expect(controller.workplaces.fetchBy(id: workplaceId) == workplace)
        #expect(controller.attendance.fetchOpenRecord(workplaceId: workplaceId)?.id == record.id)
    }

    @Test("P1-015: test_persistenceController_whenReset_clearsAllRepositories")
    func test_persistenceController_whenReset_clearsAllRepositories() {
        let controller = PersistenceController()
        let workplace = Workplace(
            id: UUID(uuidString: "CDCDCDCD-CDCD-CDCD-CDCD-CDCDCDCDCDCD")!,
            name: "Fukuoka Office",
            latitude: 33.5902,
            longitude: 130.4017,
            radius: 100,
            monitoringEnabled: true
        )

        controller.workplaces.save(workplace)
        controller.reset()

        #expect(controller.workplaces.fetchAll().isEmpty)
        #expect(controller.attendance.fetchAll().isEmpty)
        #expect(controller.corrections.fetchAll().isEmpty)
        #expect(controller.locationProofs.fetchAll().isEmpty)
    }
}
