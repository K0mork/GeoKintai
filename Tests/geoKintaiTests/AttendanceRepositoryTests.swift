import Foundation
import Testing
@testable import geoKintai

@Suite("AttendanceRepositoryTests")
struct AttendanceRepositoryTests {
    @Test("AC-05: test_attendanceRepository_whenOpenRecordExists_doesNotCreateDuplicate")
    func test_attendanceRepository_whenOpenRecordExists_doesNotCreateDuplicate() {
        let repository = AttendanceRepository()
        let workplaceId = UUID(uuidString: "AAAAAAAA-1111-1111-1111-111111111111")!
        let firstEntry = Date(timeIntervalSince1970: 1_700_100_000)
        let secondEntry = Date(timeIntervalSince1970: 1_700_100_100)

        let first = repository.createOpenRecord(workplaceId: workplaceId, entryTime: firstEntry)
        let second = repository.createOpenRecord(workplaceId: workplaceId, entryTime: secondEntry)

        #expect(first.id == second.id)
        #expect(repository.fetchBy(workplaceId: workplaceId).count == 1)
    }

    @Test("FR-07: test_attendanceRepository_whenDifferentWorkplaces_keepsRecordsSeparated")
    func test_attendanceRepository_whenDifferentWorkplaces_keepsRecordsSeparated() {
        let repository = AttendanceRepository()
        let workplaceA = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let workplaceB = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let entry = Date(timeIntervalSince1970: 1_700_101_000)

        _ = repository.createOpenRecord(workplaceId: workplaceA, entryTime: entry)
        _ = repository.createOpenRecord(workplaceId: workplaceB, entryTime: entry.addingTimeInterval(60))

        #expect(repository.fetchBy(workplaceId: workplaceA).count == 1)
        #expect(repository.fetchBy(workplaceId: workplaceB).count == 1)
        #expect(repository.fetchAll().count == 2)
    }

    @Test("AC-04: test_attendanceRepository_whenCloseOpenRecord_setsExitTime")
    func test_attendanceRepository_whenCloseOpenRecord_setsExitTime() {
        let repository = AttendanceRepository()
        let workplaceId = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
        let entryTime = Date(timeIntervalSince1970: 1_700_102_000)
        let exitTime = entryTime.addingTimeInterval(3600)

        let record = repository.createOpenRecord(workplaceId: workplaceId, entryTime: entryTime)
        let updated = repository.closeOpenRecord(workplaceId: workplaceId, exitTime: exitTime)

        #expect(updated?.id == record.id)
        #expect(updated?.exitTime == exitTime)
    }
}
