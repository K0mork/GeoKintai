import Foundation

public enum AppendOnlyGuard {
    public static func isAppendOnly<T: Equatable>(previous: [T], next: [T]) -> Bool {
        guard next.count >= previous.count else {
            return false
        }

        for (index, value) in previous.enumerated() {
            if next[index] != value {
                return false
            }
        }

        return true
    }
}
