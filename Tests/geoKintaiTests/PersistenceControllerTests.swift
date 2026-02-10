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

    @Test("P1-015: test_persistenceController_whenReinitializedWithSameStoreURL_restoresPersistedData")
    func test_persistenceController_whenReinitializedWithSameStoreURL_restoresPersistedData() {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("geokintai-persistence-tests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = tempDirectory.appendingPathComponent("store.json")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let workplaceId = UUID(uuidString: "EFEFEFEF-EFEF-EFEF-EFEF-EFEFEFEFEFEF")!
        let recordEntry = Date(timeIntervalSince1970: 1_700_300_000)
        let correctionId = UUID(uuidString: "ABCDABCD-1234-1234-1234-ABCDABCD1234")!

        do {
            let controller = PersistenceController(storeURL: storeURL)
            let workplace = Workplace(
                id: workplaceId,
                name: "Osaka Office",
                latitude: 34.6937,
                longitude: 135.5023,
                radius: 120,
                monitoringEnabled: true
            )
            controller.workplaces.save(workplace)

            let record = controller.attendance.createOpenRecord(
                workplaceId: workplaceId,
                entryTime: recordEntry
            )

            let correction = AttendanceCorrection(
                id: correctionId,
                attendanceRecordId: record.id,
                reason: "記録復元確認",
                before: AttendanceSnapshot(entryTime: record.entryTime, exitTime: nil),
                after: AttendanceSnapshot(entryTime: record.entryTime.addingTimeInterval(60), exitTime: nil),
                correctedAt: record.entryTime.addingTimeInterval(120),
                integrityHash: "hash"
            )
            controller.corrections.append(correction)

            let proof = LocationProof(
                workplaceId: workplaceId,
                attendanceRecordId: record.id,
                timestamp: record.entryTime,
                latitude: 34.6937,
                longitude: 135.5023,
                horizontalAccuracy: 5,
                reason: .stayCheck
            )
            controller.locationProofs.append(proof)
        }

        let restored = PersistenceController(storeURL: storeURL)
        #expect(restored.workplaces.fetchBy(id: workplaceId)?.name == "Osaka Office")
        #expect(restored.attendance.fetchOpenRecord(workplaceId: workplaceId)?.entryTime == recordEntry)
        #expect(restored.corrections.fetchAll().first?.id == correctionId)
        #expect(restored.locationProofs.fetchAll().count == 1)
    }

    @Test("P1-015: test_persistenceController_whenResetWithStoreURL_clearsPersistedData")
    func test_persistenceController_whenResetWithStoreURL_clearsPersistedData() {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("geokintai-persistence-tests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = tempDirectory.appendingPathComponent("store.json")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let workplace = Workplace(
            id: UUID(uuidString: "10101010-2020-3030-4040-505050505050")!,
            name: "Sapporo Office",
            latitude: 43.0618,
            longitude: 141.3545,
            radius: 100,
            monitoringEnabled: true
        )

        let controller = PersistenceController(storeURL: storeURL)
        controller.workplaces.save(workplace)
        controller.reset()

        let restored = PersistenceController(storeURL: storeURL)
        #expect(restored.workplaces.fetchAll().isEmpty)
        #expect(restored.attendance.fetchAll().isEmpty)
        #expect(restored.corrections.fetchAll().isEmpty)
        #expect(restored.locationProofs.fetchAll().isEmpty)
    }
}
