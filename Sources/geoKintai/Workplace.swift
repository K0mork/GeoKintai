import Foundation

public struct Workplace: Codable, Equatable {
    public let id: UUID
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radius: Double
    public var monitoringEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = DomainDefaults.defaultWorkplaceRadiusMeters,
        monitoringEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.monitoringEnabled = monitoringEnabled
    }
}
