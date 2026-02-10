import Foundation
import Testing
@testable import geoKintai

@Suite("ExportServiceTests")
struct ExportServiceTests {
    @Test("AC-08: test_exportService_whenCSVExport_containsRecordsProofsMetadataAndHash")
    func test_exportService_whenCSVExport_containsRecordsProofsMetadataAndHash() throws {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_300_000))
        let service = ExportService(clock: clock)

        let attendance = sampleAttendance()
        let corrections = sampleCorrections(for: attendance[0].id)
        let proofs = sampleProofs(for: attendance[0].id, workplaceId: attendance[0].workplaceId)

        let payload = try service.buildExport(
            format: .csv,
            attendance: attendance,
            corrections: corrections,
            proofs: proofs
        )

        #expect(payload.format == .csv)
        #expect(payload.generatedAt == clock.now)
        #expect(!payload.integrityHash.isEmpty)
        #expect(payload.content.contains("attendance_id"))
        #expect(payload.content.contains("correction_id"))
        #expect(payload.content.contains("proof_id"))
        #expect(payload.content.contains("generated_at"))
        #expect(payload.content.contains("integrity_hash"))
        #expect(ExportService.verify(content: payload.content, hash: payload.integrityHash))
    }

    @Test("AC-08: test_exportService_whenPDFExport_generatesPayload")
    func test_exportService_whenPDFExport_generatesPayload() throws {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_301_000))
        let service = ExportService(clock: clock)
        let attendance = sampleAttendance()
        let corrections = sampleCorrections(for: attendance[0].id)
        let proofs = sampleProofs(for: attendance[0].id, workplaceId: attendance[0].workplaceId)

        let payload = try service.buildExport(
            format: .pdf,
            attendance: attendance,
            corrections: corrections,
            proofs: proofs
        )

        #expect(payload.format == .pdf)
        #expect(payload.content.contains("PDF_EXPORT"))
        #expect(payload.content.contains("generated_at"))
        #expect(payload.content.contains("attendance_id"))
        #expect(payload.content.contains("correction_id"))
        #expect(payload.content.contains("proof_id"))
        #expect(payload.content.contains("integrity_hash"))
        #expect(ExportService.verify(content: payload.content, hash: payload.integrityHash))
    }

    @Test("AC-08: test_exportService_whenNoData_throwsReadableFailureReason")
    func test_exportService_whenNoData_throwsReadableFailureReason() {
        let service = ExportService(clock: TestClock(now: .now))

        do {
            _ = try service.buildExport(
                format: .csv,
                attendance: [],
                corrections: [],
                proofs: []
            )
            Issue.record("Expected ExportError.noData")
        } catch let error as ExportError {
            #expect(error == .noData)
            #expect(error.userMessage.contains("データ"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func sampleAttendance() -> [AttendanceRecord] {
        [
            AttendanceRecord(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                workplaceId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                entryTime: Date(timeIntervalSince1970: 1_700_100_000),
                exitTime: Date(timeIntervalSince1970: 1_700_103_600)
            )
        ]
    }

    private func sampleCorrections(for recordId: UUID) -> [AttendanceCorrection] {
        [
            AttendanceCorrection(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                attendanceRecordId: recordId,
                reason: "手動修正",
                before: AttendanceSnapshot(
                    entryTime: Date(timeIntervalSince1970: 1_700_100_000),
                    exitTime: Date(timeIntervalSince1970: 1_700_103_000)
                ),
                after: AttendanceSnapshot(
                    entryTime: Date(timeIntervalSince1970: 1_700_100_000),
                    exitTime: Date(timeIntervalSince1970: 1_700_103_600)
                ),
                correctedAt: Date(timeIntervalSince1970: 1_700_104_000),
                integrityHash: "h-correction"
            )
        ]
    }

    private func sampleProofs(for recordId: UUID, workplaceId: UUID) -> [LocationProof] {
        [
            LocationProof(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                workplaceId: workplaceId,
                attendanceRecordId: recordId,
                timestamp: Date(timeIntervalSince1970: 1_700_100_100),
                latitude: 35.0,
                longitude: 139.0,
                horizontalAccuracy: 6,
                reason: .stayCheck
            )
        ]
    }
}
