import Foundation
import Testing
@testable import geoKintai

@Suite("LoggingServiceTests")
struct LoggingServiceTests {
    @Test("NFR-05: test_loggingService_whenLogMajorEvents_recordsAll")
    func test_loggingService_whenLogMajorEvents_recordsAll() {
        let logger = LoggingService(clock: TestClock(now: Date(timeIntervalSince1970: 1_700_400_000)))

        logger.log(.didEnterRegion(workplaceId: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!))
        logger.log(.stayConfirmed(recordId: UUID(uuidString: "66666666-7777-8888-9999-AAAAAAAAAAAA")!))
        logger.log(.didExitRegion(workplaceId: UUID(uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF")!))
        logger.log(.exitConfirmed(recordId: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!))

        let events = logger.allEvents()
        #expect(events.count == 4)
        #expect(events[0].message.contains("didEnterRegion"))
        #expect(events[1].message.contains("stayConfirmed"))
        #expect(events[2].message.contains("didExitRegion"))
        #expect(events[3].message.contains("exitConfirmed"))
    }

    @Test("NFR-05: test_loggingService_whenFailure_logsClassifiedError")
    func test_loggingService_whenFailure_logsClassifiedError() {
        let logger = LoggingService(clock: TestClock(now: Date(timeIntervalSince1970: 1_700_400_100)))

        logger.log(.failure(type: .persistenceWriteFailed, detail: "disk full"))
        let event = logger.allEvents().last

        #expect(event?.level == .error)
        #expect(event?.message.contains("persistenceWriteFailed") == true)
        #expect(event?.message.contains("disk full") == true)
    }
}
