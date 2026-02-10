import Foundation

public struct AttendanceRecord: Equatable {
    public let id: UUID
    public let workplaceId: UUID
    public let entryTime: Date
    public var exitTime: Date?

    public init(
        id: UUID = UUID(),
        workplaceId: UUID,
        entryTime: Date,
        exitTime: Date? = nil
    ) {
        self.id = id
        self.workplaceId = workplaceId
        self.entryTime = entryTime
        self.exitTime = exitTime
    }
}
