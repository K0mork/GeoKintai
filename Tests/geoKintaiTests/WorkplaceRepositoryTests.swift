import Foundation
import Testing
@testable import geoKintai

@Suite("WorkplaceRepositoryTests")
struct WorkplaceRepositoryTests {
    @Test("AC-01: test_workplaceRepository_whenSaveAndLoad_persistsAllFields")
    func test_workplaceRepository_whenSaveAndLoad_persistsAllFields() {
        let repository = WorkplaceRepository()
        let workplace = Workplace(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            name: "Tokyo Office",
            latitude: 35.681236,
            longitude: 139.767125,
            radius: 120,
            monitoringEnabled: true
        )

        repository.save(workplace)

        let loaded = repository.fetchAll()
        #expect(loaded.count == 1)
        #expect(loaded.first == workplace)
    }

    @Test("AC-01: test_workplaceRepository_whenDelete_removesWorkplace")
    func test_workplaceRepository_whenDelete_removesWorkplace() {
        let repository = WorkplaceRepository()
        let workplace = Workplace(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            name: "Osaka Office",
            latitude: 34.6937,
            longitude: 135.5023,
            radius: 100,
            monitoringEnabled: false
        )
        repository.save(workplace)

        repository.delete(id: workplace.id)

        #expect(repository.fetchAll().isEmpty)
    }
}
