import Foundation
import Testing
@testable import geoKintai

@Suite("IntegrityHashTests")
struct IntegrityHashTests {
    @Test("FR-10: test_integrityHash_whenCorrectionUnchanged_verificationSucceeds")
    func test_integrityHash_whenCorrectionUnchanged_verificationSucceeds() {
        let correction = sampleCorrection(reason: "打刻漏れ修正")
        let hash = IntegrityHashService.hashCorrection(correction)

        #expect(IntegrityHashService.verifyCorrection(correction, hash: hash))
    }

    @Test("FR-10: test_integrityHash_whenCorrectionChanged_verificationFails")
    func test_integrityHash_whenCorrectionChanged_verificationFails() {
        let original = sampleCorrection(reason: "打刻漏れ修正")
        let hash = IntegrityHashService.hashCorrection(original)
        let tampered = sampleCorrection(reason: "理由改ざん")

        #expect(!IntegrityHashService.verifyCorrection(tampered, hash: hash))
    }

    @Test("FR-10: test_integrityHash_whenProofChanged_verificationFails")
    func test_integrityHash_whenProofChanged_verificationFails() {
        let proof = sampleProof(reason: .stayCheck)
        let hash = IntegrityHashService.hashLocationProof(proof)
        let tampered = LocationProof(
            id: proof.id,
            workplaceId: proof.workplaceId,
            attendanceRecordId: proof.attendanceRecordId,
            timestamp: proof.timestamp,
            latitude: proof.latitude,
            longitude: proof.longitude,
            horizontalAccuracy: 30,
            reason: proof.reason
        )

        #expect(!IntegrityHashService.verifyLocationProof(tampered, hash: hash))
    }

    private func sampleCorrection(reason: String) -> AttendanceCorrection {
        let base = Date(timeIntervalSince1970: 1_700_210_000)
        return AttendanceCorrection(
            id: UUID(uuidString: "55555555-6666-7777-8888-999999999999")!,
            attendanceRecordId: UUID(uuidString: "AAAAAAAA-9999-9999-9999-999999999999")!,
            reason: reason,
            before: AttendanceSnapshot(entryTime: base, exitTime: nil),
            after: AttendanceSnapshot(entryTime: base.addingTimeInterval(60), exitTime: nil),
            correctedAt: base.addingTimeInterval(120),
            integrityHash: "ignored-in-test"
        )
    }

    private func sampleProof(reason: LocationProofReason) -> LocationProof {
        LocationProof(
            id: UUID(uuidString: "99999999-8888-7777-6666-555555555555")!,
            workplaceId: UUID(uuidString: "11111111-AAAA-BBBB-CCCC-222222222222")!,
            attendanceRecordId: UUID(uuidString: "33333333-DDDD-EEEE-FFFF-444444444444")!,
            timestamp: Date(timeIntervalSince1970: 1_700_220_000),
            latitude: 35.6812,
            longitude: 139.7671,
            horizontalAccuracy: 5,
            reason: reason
        )
    }
}
