import Foundation

public final class AttendanceCorrectionRepository {
    private var corrections: [AttendanceCorrection]
    public var onChange: (([AttendanceCorrection]) -> Void)?

    public init(
        initialCorrections: [AttendanceCorrection] = [],
        onChange: (([AttendanceCorrection]) -> Void)? = nil
    ) {
        self.corrections = initialCorrections
        self.onChange = onChange
    }

    public func append(_ correction: AttendanceCorrection) {
        corrections.append(correction)
        onChange?(corrections)
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
