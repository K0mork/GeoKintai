import Foundation
@testable import geoKintai

final class TestClock: VerificationClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }

    func advance(seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
