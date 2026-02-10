import Foundation

public final class AttendanceRepository {
    private var records: [AttendanceRecord]

    public init(initialRecords: [AttendanceRecord] = []) {
        self.records = initialRecords
    }

    public func createOpenRecord(workplaceId: UUID, entryTime: Date) -> AttendanceRecord {
        if let existing = fetchOpenRecord(workplaceId: workplaceId) {
            return existing
        }

        let record = AttendanceRecord(
            workplaceId: workplaceId,
            entryTime: entryTime,
            exitTime: nil
        )
        records.append(record)
        return record
    }

    public func closeOpenRecord(workplaceId: UUID, exitTime: Date) -> AttendanceRecord? {
        guard let index = records.firstIndex(where: { $0.workplaceId == workplaceId && $0.exitTime == nil }) else {
            return nil
        }

        records[index].exitTime = exitTime
        return records[index]
    }

    public func fetchOpenRecord(workplaceId: UUID) -> AttendanceRecord? {
        records.first(where: { $0.workplaceId == workplaceId && $0.exitTime == nil })
    }

    public func fetchBy(workplaceId: UUID) -> [AttendanceRecord] {
        records.filter { $0.workplaceId == workplaceId }
    }

    public func fetchAll() -> [AttendanceRecord] {
        records
    }
}
