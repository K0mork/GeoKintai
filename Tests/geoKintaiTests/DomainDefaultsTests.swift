import Foundation
import Testing
@testable import geoKintai

@Suite("DomainDefaultsTests")
struct DomainDefaultsTests {
    @Test("固定値: 滞在5分/再確認2分/半径100m")
    func test_domainDefaults_hasExpectedFixedValues() {
        #expect(DomainDefaults.stayDuration == 5 * 60)
        #expect(DomainDefaults.exitRecheckDuration == 2 * 60)
        #expect(DomainDefaults.defaultWorkplaceRadiusMeters == 100)
    }
}
