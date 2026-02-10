import Foundation
import Testing
@testable import geoKintai

@Suite("RegionRoutingTests")
struct RegionRoutingTests {
    @Test("FR-07: test_regionRouter_whenMultipleBindings_routesToCorrectWorkplace")
    func test_regionRouter_whenMultipleBindings_routesToCorrectWorkplace() {
        let workplaceA = UUID(uuidString: "AAAA0000-0000-0000-0000-000000000000")!
        let workplaceB = UUID(uuidString: "BBBB0000-0000-0000-0000-000000000000")!
        let router = RegionRouter(
            bindings: [
                "region-a": workplaceA,
                "region-b": workplaceB
            ]
        )

        #expect(router.resolveWorkplaceId(forRegionIdentifier: "region-a") == workplaceA)
        #expect(router.resolveWorkplaceId(forRegionIdentifier: "region-b") == workplaceB)
    }

    @Test("FR-07: test_regionRouter_whenUnknownRegion_returnsNil")
    func test_regionRouter_whenUnknownRegion_returnsNil() {
        let router = RegionRouter(bindings: [:])

        #expect(router.resolveWorkplaceId(forRegionIdentifier: "unknown") == nil)
    }
}
