import Foundation

public final class AttendanceCorrectionRepository {
    private var corrections: [AttendanceCorrection]

    public init(initialCorrections: [AttendanceCorrection] = []) {
        self.corrections = initialCorrections
    }

    public func append(_ correction: AttendanceCorrection) {
        corrections.append(correction)
    }

    public func fetchBy(attendanceRecordId: UUID) -> [AttendanceCorrection] {
        corrections
            .filter { $0.attendanceRecordId == attendanceRecordId }
            .sorted { $0.correctedAt < $1.correctedAt }
    }

    public func fetchAll() -> [AttendanceCorrection] {
        corrections
    }
}
