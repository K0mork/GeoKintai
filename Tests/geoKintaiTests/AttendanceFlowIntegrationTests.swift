import Foundation
import Testing
@testable import geoKintai

@Suite("AttendanceFlowIntegrationTests")
struct AttendanceFlowIntegrationTests {
    @Test("P3-020: test_attendanceFlow_whenInsideFor5Minutes_createsAttendanceAndProof")
    func test_attendanceFlow_whenInsideFor5Minutes_createsAttendanceAndProof() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_500_000))
        let attendance = AttendanceRepository()
        let proofs = LocationProofRepository()
        let coordinator = AttendanceFlowCoordinator(
            attendanceRepository: attendance,
            proofRepository: proofs,
            clock: clock
        )
        let workplace = sampleWorkplace()

        coordinator.handleDidEnter(workplace: workplace)
        #expect(coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 20) == .none)

        clock.advance(seconds: 299)
        #expect(coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 15) == .none)

        clock.advance(seconds: 1)
        let outcome = coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 10)

        guard case .entryConfirmed(let recordId) = outcome else {
            Issue.record("Expected entry confirmation")
            return
        }

        let records = attendance.fetchBy(workplaceId: workplace.id)
        #expect(records.count == 1)
        #expect(records[0].id == recordId)
        #expect(proofs.fetchBy(attendanceRecordId: recordId).first?.reason == .stayCheck)
    }

    @Test("P3-020: test_attendanceFlow_whenLeaveBefore5Minutes_doesNotCreateAttendance")
    func test_attendanceFlow_whenLeaveBefore5Minutes_doesNotCreateAttendance() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_501_000))
        let attendance = AttendanceRepository()
        let proofs = LocationProofRepository()
        let coordinator = AttendanceFlowCoordinator(
            attendanceRepository: attendance,
            proofRepository: proofs,
            clock: clock
        )
        let workplace = sampleWorkplace()

        coordinator.handleDidEnter(workplace: workplace)
        _ = coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 10)
        clock.advance(seconds: 120)
        let outcome = coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 130)

        #expect(outcome == .entryCancelled)
        #expect(attendance.fetchBy(workplaceId: workplace.id).isEmpty)
        #expect(proofs.fetchBy(workplaceId: workplace.id).isEmpty)
    }

    @Test("P3-020: test_attendanceFlow_whenOutside2MinutesAfterExit_closesRecordAndSavesProof")
    func test_attendanceFlow_whenOutside2MinutesAfterExit_closesRecordAndSavesProof() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_502_000))
        let attendance = AttendanceRepository()
        let proofs = LocationProofRepository()
        let coordinator = AttendanceFlowCoordinator(
            attendanceRepository: attendance,
            proofRepository: proofs,
            clock: clock
        )
        let workplace = sampleWorkplace()
        let open = attendance.createOpenRecord(workplaceId: workplace.id, entryTime: clock.now)

        coordinator.handleDidExit(workplace: workplace)
        #expect(coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 130) == .none)

        clock.advance(seconds: 120)
        let outcome = coordinator.handleLocationUpdate(workplace: workplace, distanceFromCenterMeters: 120)

        guard case .exitConfirmed(let recordId) = outcome else {
            Issue.record("Expected exit confirmation")
            return
        }

        let updated = attendance.fetchBy(workplaceId: workplace.id).first(where: { $0.id == open.id })
        #expect(updated?.exitTime == clock.now)
        #expect(recordId == open.id)
        #expect(proofs.fetchBy(attendanceRecordId: open.id).last?.reason == .exitCheck)
    }

    @Test("P3-021: test_attendanceFlow_whenMultipleWorkplaces_tracksStateIndependently")
    func test_attendanceFlow_whenMultipleWorkplaces_tracksStateIndependently() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_503_000))
        let attendance = AttendanceRepository()
        let proofs = LocationProofRepository()
        let coordinator = AttendanceFlowCoordinator(
            attendanceRepository: attendance,
            proofRepository: proofs,
            clock: clock
        )
        let workplaceA = sampleWorkplace(
            id: UUID(uuidString: "AAAA0000-0000-0000-0000-000000000001")!,
            name: "Office A"
        )
        let workplaceB = sampleWorkplace(
            id: UUID(uuidString: "BBBB0000-0000-0000-0000-000000000002")!,
            name: "Office B"
        )

        coordinator.handleDidEnter(workplace: workplaceA)
        coordinator.handleDidEnter(workplace: workplaceB)
        #expect(coordinator.handleLocationUpdate(workplace: workplaceA, distanceFromCenterMeters: 15) == .none)
        #expect(coordinator.handleLocationUpdate(workplace: workplaceB, distanceFromCenterMeters: 140) == .none)

        clock.advance(seconds: 300)
        let outcomeA = coordinator.handleLocationUpdate(workplace: workplaceA, distanceFromCenterMeters: 10)
        guard case .entryConfirmed(let recordIdA) = outcomeA else {
            Issue.record("Expected entry confirmation for workplace A")
            return
        }

        #expect(attendance.fetchBy(workplaceId: workplaceA.id).count == 1)
        #expect(attendance.fetchBy(workplaceId: workplaceB.id).isEmpty)
        #expect(proofs.fetchBy(attendanceRecordId: recordIdA).first?.workplaceId == workplaceA.id)

        #expect(coordinator.handleLocationUpdate(workplace: workplaceB, distanceFromCenterMeters: 20) == .none)
        clock.advance(seconds: 300)
        let outcomeB = coordinator.handleLocationUpdate(workplace: workplaceB, distanceFromCenterMeters: 5)

        guard case .entryConfirmed(let recordIdB) = outcomeB else {
            Issue.record("Expected entry confirmation for workplace B")
            return
        }

        #expect(attendance.fetchBy(workplaceId: workplaceB.id).count == 1)
        #expect(proofs.fetchBy(attendanceRecordId: recordIdB).first?.workplaceId == workplaceB.id)
    }

    private func sampleWorkplace(
        id: UUID = UUID(uuidString: "ABCDABCD-ABCD-ABCD-ABCD-ABCDABCDABCD")!,
        name: String = "Test Office"
    ) -> Workplace {
        Workplace(
            id: id,
            name: name,
            latitude: 35.0,
            longitude: 139.0,
            radius: 100,
            monitoringEnabled: true
        )
    }
}
