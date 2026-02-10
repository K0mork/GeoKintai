import Foundation
import Testing
@testable import geoKintai

@Suite("AuditLogAppendOnlyTests")
struct AuditLogAppendOnlyTests {
    @Test("NFR-04: test_appendOnlyGuard_whenOnlyAppend_returnsTrue")
    func test_appendOnlyGuard_whenOnlyAppend_returnsTrue() {
        let oldValues = [1, 2, 3]
        let newValues = [1, 2, 3, 4]

        #expect(AppendOnlyGuard.isAppendOnly(previous: oldValues, next: newValues))
    }

    @Test("NFR-04: test_appendOnlyGuard_whenOverwriteExisting_returnsFalse")
    func test_appendOnlyGuard_whenOverwriteExisting_returnsFalse() {
        let oldValues = [1, 2, 3]
        let newValues = [1, 9, 3, 4]

        #expect(!AppendOnlyGuard.isAppendOnly(previous: oldValues, next: newValues))
    }

    @Test("NFR-04: test_appendOnlyGuard_whenDeleteExisting_returnsFalse")
    func test_appendOnlyGuard_whenDeleteExisting_returnsFalse() {
        let oldValues = [1, 2, 3]
        let newValues = [1, 2]

        #expect(!AppendOnlyGuard.isAppendOnly(previous: oldValues, next: newValues))
    }
}
