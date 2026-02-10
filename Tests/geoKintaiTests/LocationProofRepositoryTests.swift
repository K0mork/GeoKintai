import Foundation
import Testing
@testable import geoKintai

@Suite("LocationProofRepositoryTests")
struct LocationProofRepositoryTests {
    @Test("NFR-03: test_locationProofRepository_whenAppendAndFilter_tracksByRecord")
    func test_locationProofRepository_whenAppendAndFilter_tracksByRecord() {
        let repository = LocationProofRepository()
        let workplaceId = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        let recordA = UUID(uuidString: "AAAAAAAA-2222-2222-2222-222222222222")!
        let recordB = UUID(uuidString: "BBBBBBBB-3333-3333-3333-333333333333")!
        let base = Date(timeIntervalSince1970: 1_700_104_000)

        let proofA = LocationProof(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            workplaceId: workplaceId,
            attendanceRecordId: recordA,
            timestamp: base,
            latitude: 35.0,
            longitude: 139.0,
            horizontalAccuracy: 8,
            reason: .stayCheck
        )

        let proofB = LocationProof(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            workplaceId: workplaceId,
            attendanceRecordId: recordB,
            timestamp: base.addingTimeInterval(60),
            latitude: 35.001,
            longitude: 139.001,
            horizontalAccuracy: 7,
            reason: .exitCheck
        )

        repository.append(proofA)
        repository.append(proofB)

        #expect(repository.fetchBy(attendanceRecordId: recordA) == [proofA])
        #expect(repository.fetchBy(attendanceRecordId: recordB) == [proofB])
    }
}
