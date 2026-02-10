import Foundation

public final class PersistenceController {
    public private(set) var workplaces: WorkplaceRepository
    public private(set) var attendance: AttendanceRepository
    public private(set) var corrections: AttendanceCorrectionRepository
    public private(set) var locationProofs: LocationProofRepository

    public init() {
        workplaces = WorkplaceRepository()
        attendance = AttendanceRepository()
        corrections = AttendanceCorrectionRepository()
        locationProofs = LocationProofRepository()
    }

    public func reset() {
        workplaces = WorkplaceRepository()
        attendance = AttendanceRepository()
        corrections = AttendanceCorrectionRepository()
        locationProofs = LocationProofRepository()
    }
}
