import Foundation

public final class StayVerifier {
    public enum Decision: Equatable {
        case pending
        case confirmed(at: Date)
        case cancelledEarlyExit(at: Date)
    }

    private let requiredStayDuration: TimeInterval
    private let clock: VerificationClock
    private var insideSince: Date?
    private var terminalDecision: Decision?

    public init(
        requiredStayDuration: TimeInterval = DomainDefaults.stayDuration,
        clock: VerificationClock
    ) {
        self.requiredStayDuration = requiredStayDuration
        self.clock = clock
    }

    public func onLocation(distanceFromCenterMeters: Double, radiusMeters: Double) -> Decision {
        if let terminalDecision {
            return terminalDecision
        }

        let now = clock.now
        let isInside = distanceFromCenterMeters <= radiusMeters

        if isInside {
            if let insideSince {
                if now.timeIntervalSince(insideSince) >= requiredStayDuration {
                    let decision = Decision.confirmed(at: now)
                    terminalDecision = decision
                    return decision
                }
            } else {
                insideSince = now
            }

            return .pending
        }

        if let insideSince, now.timeIntervalSince(insideSince) < requiredStayDuration {
            let decision = Decision.cancelledEarlyExit(at: now)
            terminalDecision = decision
            return decision
        }

        self.insideSince = nil
        return .pending
    }
}
