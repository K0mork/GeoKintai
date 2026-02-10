import Foundation

public enum LocationProofReason: String, Codable, Equatable {
    case entryTrigger
    case stayCheck
    case exitCheck
}

public struct LocationProof: Codable, Equatable {
    public let id: UUID
    public let workplaceId: UUID
    public let attendanceRecordId: UUID
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double
    public let reason: LocationProofReason

    public init(
        id: UUID = UUID(),
        workplaceId: UUID,
        attendanceRecordId: UUID,
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        reason: LocationProofReason
    ) {
        self.id = id
        self.workplaceId = workplaceId
        self.attendanceRecordId = attendanceRecordId
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.reason = reason
    }
}
