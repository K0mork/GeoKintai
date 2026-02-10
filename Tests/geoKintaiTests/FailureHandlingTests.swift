import Foundation
import Testing
@testable import geoKintai

@Suite("FailureHandlingTests")
struct FailureHandlingTests {
    @Test("NFR-06: test_failureHandling_whenLocationUnavailable_preservesDataAndRetries")
    func test_failureHandling_whenLocationUnavailable_preservesDataAndRetries() {
        let useCase = FailureHandlingUseCase()

        let action = useCase.handle(.locationUnavailable)

        #expect(action.shouldPreserveExistingData)
        #expect(action.shouldRetry)
        #expect(action.userMessage.contains("位置"))
    }

    @Test("NFR-06: test_failureHandling_whenPersistenceWriteFailed_preservesDataAndStopsCurrentCycle")
    func test_failureHandling_whenPersistenceWriteFailed_preservesDataAndStopsCurrentCycle() {
        let useCase = FailureHandlingUseCase()

        let action = useCase.handle(.persistenceWriteFailed)

        #expect(action.shouldPreserveExistingData)
        #expect(!action.shouldRetry)
        #expect(action.userMessage.contains("保存"))
    }
}
