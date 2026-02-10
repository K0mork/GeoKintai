import Foundation

public enum LogLevel: Equatable {
    case info
    case error
}

public enum FailureType: Equatable {
    case locationUnavailable
    case persistenceWriteFailed
    case permissionInsufficient
}

public enum LogEventType: Equatable {
    case didEnterRegion(workplaceId: UUID)
    case stayConfirmed(recordId: UUID)
    case didExitRegion(workplaceId: UUID)
    case exitConfirmed(recordId: UUID)
    case failure(type: FailureType, detail: String)
}

public struct LogEvent: Equatable {
    public let timestamp: Date
    public let level: LogLevel
    public let message: String

    public init(timestamp: Date, level: LogLevel, message: String) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}

public final class LoggingService {
    private let clock: VerificationClock
    private var events: [LogEvent] = []

    public init(clock: VerificationClock) {
        self.clock = clock
    }

    public func log(_ eventType: LogEventType) {
        let event: LogEvent

        switch eventType {
        case .didEnterRegion(let workplaceId):
            event = LogEvent(
                timestamp: clock.now,
                level: .info,
                message: "didEnterRegion workplaceId=\(workplaceId.uuidString)"
            )
        case .stayConfirmed(let recordId):
            event = LogEvent(
                timestamp: clock.now,
                level: .info,
                message: "stayConfirmed recordId=\(recordId.uuidString)"
            )
        case .didExitRegion(let workplaceId):
            event = LogEvent(
                timestamp: clock.now,
                level: .info,
                message: "didExitRegion workplaceId=\(workplaceId.uuidString)"
            )
        case .exitConfirmed(let recordId):
            event = LogEvent(
                timestamp: clock.now,
                level: .info,
                message: "exitConfirmed recordId=\(recordId.uuidString)"
            )
        case .failure(let type, let detail):
            event = LogEvent(
                timestamp: clock.now,
                level: .error,
                message: "failure type=\(type.rawValue) detail=\(detail)"
            )
        }

        events.append(event)
    }

    public func allEvents() -> [LogEvent] {
        events
    }
}

private extension FailureType {
    var rawValue: String {
        switch self {
        case .locationUnavailable:
            return "locationUnavailable"
        case .persistenceWriteFailed:
            return "persistenceWriteFailed"
        case .permissionInsufficient:
            return "permissionInsufficient"
        }
    }
}
