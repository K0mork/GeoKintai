import Foundation

public final class ExitVerifier {
    public enum Decision: Equatable {
        case pending
        case confirmed(at: Date)
    }

    private let requiredOutsideDuration: TimeInterval
    private let clock: VerificationClock
    private var outsideSince: Date?
    private var terminalDecision: Decision?

    public init(
        requiredOutsideDuration: TimeInterval = DomainDefaults.exitRecheckDuration,
        clock: VerificationClock
    ) {
        self.requiredOutsideDuration = requiredOutsideDuration
        self.clock = clock
    }

    public func onLocation(distanceFromCenterMeters: Double, radiusMeters: Double) -> Decision {
        if let terminalDecision {
            return terminalDecision
        }

        let now = clock.now
        let isOutside = distanceFromCenterMeters > radiusMeters

        if isOutside {
            if let outsideSince {
                if now.timeIntervalSince(outsideSince) >= requiredOutsideDuration {
                    let decision = Decision.confirmed(at: now)
                    terminalDecision = decision
                    return decision
                }
            } else {
                outsideSince = now
            }

            return .pending
        }

        outsideSince = nil
        return .pending
    }
}
