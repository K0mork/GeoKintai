import Foundation

public struct AttendanceSnapshot: Codable, Equatable {
    public var entryTime: Date
    public var exitTime: Date?

    public init(entryTime: Date, exitTime: Date?) {
        self.entryTime = entryTime
        self.exitTime = exitTime
    }
}

public struct AttendanceCorrection: Codable, Equatable {
    public let id: UUID
    public let attendanceRecordId: UUID
    public let reason: String
    public let before: AttendanceSnapshot
    public let after: AttendanceSnapshot
    public let correctedAt: Date
    public let integrityHash: String

    public init(
        id: UUID = UUID(),
        attendanceRecordId: UUID,
        reason: String,
        before: AttendanceSnapshot,
        after: AttendanceSnapshot,
        correctedAt: Date,
        integrityHash: String
    ) {
        self.id = id
        self.attendanceRecordId = attendanceRecordId
        self.reason = reason
        self.before = before
        self.after = after
        self.correctedAt = correctedAt
        self.integrityHash = integrityHash
    }
}
