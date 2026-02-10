import Foundation

public struct FailureHandlingAction: Equatable {
    public let shouldRetry: Bool
    public let shouldPreserveExistingData: Bool
    public let userMessage: String

    public init(shouldRetry: Bool, shouldPreserveExistingData: Bool, userMessage: String) {
        self.shouldRetry = shouldRetry
        self.shouldPreserveExistingData = shouldPreserveExistingData
        self.userMessage = userMessage
    }
}

public struct FailureHandlingUseCase {
    public init() {}

    public func handle(_ failure: FailureType) -> FailureHandlingAction {
        switch failure {
        case .locationUnavailable:
            return FailureHandlingAction(
                shouldRetry: true,
                shouldPreserveExistingData: true,
                userMessage: "位置情報の取得に失敗しました。現在のデータを保持したまま再試行します。"
            )
        case .persistenceWriteFailed:
            return FailureHandlingAction(
                shouldRetry: false,
                shouldPreserveExistingData: true,
                userMessage: "保存処理に失敗しました。既存データを保持し、現在の処理を中断します。"
            )
        case .permissionInsufficient:
            return FailureHandlingAction(
                shouldRetry: false,
                shouldPreserveExistingData: true,
                userMessage: "権限が不足しています。設定から権限を変更してください。"
            )
        }
    }
}
