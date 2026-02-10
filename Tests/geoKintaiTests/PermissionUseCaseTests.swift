import Foundation
import Testing
@testable import geoKintai

@Suite("PermissionUseCaseTests")
struct PermissionUseCaseTests {
    @Test("AC-09: test_permissionUseCase_whenAlwaysAuthorized_allowsAutoRecording")
    func test_permissionUseCase_whenAlwaysAuthorized_allowsAutoRecording() {
        let useCase = PermissionUseCase()

        let decision = useCase.evaluate(status: .always, requiresBackgroundRecording: true)

        #expect(decision.shouldRunAutoRecording)
        #expect(decision.guidance == .none)
    }

    @Test("AC-09: test_permissionUseCase_whenWhenInUse_stopsAutoRecordingAndShowsSettingsGuidance")
    func test_permissionUseCase_whenWhenInUse_stopsAutoRecordingAndShowsSettingsGuidance() {
        let useCase = PermissionUseCase()

        let decision = useCase.evaluate(status: .whenInUse, requiresBackgroundRecording: true)

        #expect(!decision.shouldRunAutoRecording)
        #expect(decision.guidance == .openSettings)
    }

    @Test("AC-09: test_permissionUseCase_whenDenied_stopsAutoRecordingAndShowsSettingsGuidance")
    func test_permissionUseCase_whenDenied_stopsAutoRecordingAndShowsSettingsGuidance() {
        let useCase = PermissionUseCase()

        let decision = useCase.evaluate(status: .denied, requiresBackgroundRecording: true)

        #expect(!decision.shouldRunAutoRecording)
        #expect(decision.guidance == .openSettings)
    }
}
