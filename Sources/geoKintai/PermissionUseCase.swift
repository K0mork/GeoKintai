import Foundation

public enum LocationPermissionStatus: Equatable, Hashable, CaseIterable {
    case always
    case whenInUse
    case denied
    case notDetermined
}

public enum PermissionGuidance: Equatable, Hashable {
    case none
    case openSettings
}

public struct PermissionDecision: Equatable {
    public let shouldRunAutoRecording: Bool
    public let guidance: PermissionGuidance

    public init(shouldRunAutoRecording: Bool, guidance: PermissionGuidance) {
        self.shouldRunAutoRecording = shouldRunAutoRecording
        self.guidance = guidance
    }
}

public struct PermissionUseCase {
    public init() {}

    public func evaluate(
        status: LocationPermissionStatus,
        requiresBackgroundRecording: Bool
    ) -> PermissionDecision {
        guard requiresBackgroundRecording else {
            return PermissionDecision(shouldRunAutoRecording: true, guidance: .none)
        }

        switch status {
        case .always:
            return PermissionDecision(shouldRunAutoRecording: true, guidance: .none)
        case .whenInUse:
            return PermissionDecision(shouldRunAutoRecording: false, guidance: .openSettings)
        case .denied:
            return PermissionDecision(shouldRunAutoRecording: false, guidance: .openSettings)
        case .notDetermined:
            return PermissionDecision(shouldRunAutoRecording: false, guidance: .openSettings)
        }
    }
}
