import Foundation

public protocol VerificationClock {
    var now: Date { get }
}

public struct SystemVerificationClock: VerificationClock {
    public init() {}

    public var now: Date {
        Date()
    }
}
