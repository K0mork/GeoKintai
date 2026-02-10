import Foundation

public struct RegionRouter {
    private let bindings: [String: UUID]

    public init(bindings: [String: UUID]) {
        self.bindings = bindings
    }

    public func resolveWorkplaceId(forRegionIdentifier identifier: String) -> UUID? {
        bindings[identifier]
    }
}
