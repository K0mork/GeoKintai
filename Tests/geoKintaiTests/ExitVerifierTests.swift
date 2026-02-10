import Foundation
import Testing
@testable import geoKintai

@Suite("ExitVerifierTests")
struct ExitVerifierTests {
    @Test("AC-04: test_exitVerifier_whenOutsideFor2Minutes_returnsConfirmed")
    func test_exitVerifier_whenOutsideFor2Minutes_returnsConfirmed() {
        let start = Date(timeIntervalSince1970: 1_700_002_000)
        let clock = TestClock(now: start)
        let verifier = ExitVerifier(clock: clock)

        #expect(verifier.onLocation(distanceFromCenterMeters: 130, radiusMeters: 100) == .pending)

        clock.advance(seconds: 119)
        #expect(verifier.onLocation(distanceFromCenterMeters: 150, radiusMeters: 100) == .pending)

        clock.advance(seconds: 1)
        #expect(verifier.onLocation(distanceFromCenterMeters: 120, radiusMeters: 100) == .confirmed(at: clock.now))
    }

    @Test("AC-04: test_exitVerifier_whenReturnInsideDuringRecheck_resetsCountdown")
    func test_exitVerifier_whenReturnInsideDuringRecheck_resetsCountdown() {
        let start = Date(timeIntervalSince1970: 1_700_003_000)
        let clock = TestClock(now: start)
        let verifier = ExitVerifier(clock: clock)

        #expect(verifier.onLocation(distanceFromCenterMeters: 130, radiusMeters: 100) == .pending)

        clock.advance(seconds: 90)
        #expect(verifier.onLocation(distanceFromCenterMeters: 140, radiusMeters: 100) == .pending)

        clock.advance(seconds: 1)
        #expect(verifier.onLocation(distanceFromCenterMeters: 50, radiusMeters: 100) == .pending)

        clock.advance(seconds: 70)
        #expect(verifier.onLocation(distanceFromCenterMeters: 125, radiusMeters: 100) == .pending)
    }
}
