import Foundation
import Testing
@testable import geoKintai

@Suite("StayVerifierTests")
struct StayVerifierTests {
    @Test("AC-02: test_stayVerifier_whenInsideFor5Minutes_returnsConfirmed")
    func test_stayVerifier_whenInsideFor5Minutes_returnsConfirmed() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = TestClock(now: start)
        let verifier = StayVerifier(clock: clock)

        #expect(verifier.onLocation(distanceFromCenterMeters: 20, radiusMeters: 100) == .pending)

        clock.advance(seconds: 299)
        #expect(verifier.onLocation(distanceFromCenterMeters: 15, radiusMeters: 100) == .pending)

        clock.advance(seconds: 1)
        #expect(verifier.onLocation(distanceFromCenterMeters: 10, radiusMeters: 100) == .confirmed(at: clock.now))
    }

    @Test("AC-03: test_stayVerifier_whenExitBefore5Minutes_returnsCancelled")
    func test_stayVerifier_whenExitBefore5Minutes_returnsCancelled() {
        let start = Date(timeIntervalSince1970: 1_700_001_000)
        let clock = TestClock(now: start)
        let verifier = StayVerifier(clock: clock)

        #expect(verifier.onLocation(distanceFromCenterMeters: 25, radiusMeters: 100) == .pending)

        clock.advance(seconds: 270)
        #expect(verifier.onLocation(distanceFromCenterMeters: 150, radiusMeters: 100) == .cancelledEarlyExit(at: clock.now))
    }
}
