import Foundation
import Testing
@testable import geoKintai

@Suite("AttendanceCorrectionRepositoryTests")
struct AttendanceCorrectionRepositoryTests {
    @Test("AC-06: test_correctionRepository_whenAppend_savesAuditEntriesInOrder")
    func test_correctionRepository_whenAppend_savesAuditEntriesInOrder() {
        let repository = AttendanceCorrectionRepository()
        let recordId = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
        let baseTime = Date(timeIntervalSince1970: 1_700_103_000)

        let before = AttendanceSnapshot(entryTime: baseTime, exitTime: nil)
        let after1 = AttendanceSnapshot(entryTime: baseTime.addingTimeInterval(60), exitTime: nil)
        let after2 = AttendanceSnapshot(entryTime: baseTime.addingTimeInterval(120), exitTime: nil)

        let first = AttendanceCorrection(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            attendanceRecordId: recordId,
            reason: "打刻漏れ修正",
            before: before,
            after: after1,
            correctedAt: baseTime.addingTimeInterval(180),
            integrityHash: "hash-1"
        )

        let second = AttendanceCorrection(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            attendanceRecordId: recordId,
            reason: "再修正",
            before: after1,
            after: after2,
            correctedAt: baseTime.addingTimeInterval(240),
            integrityHash: "hash-2"
        )

        repository.append(first)
        repository.append(second)

        #expect(repository.fetchBy(attendanceRecordId: recordId) == [first, second])
    }
}
