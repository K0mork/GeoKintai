import Foundation

@MainActor
final class StatusViewModel: ObservableObject {
    enum DutyStatus: String {
        case onDuty = "On Duty"
        case offDuty = "Off Duty"
    }

    @Published private(set) var status: DutyStatus = .offDuty
    @Published private(set) var errorMessage: String?
    let sectionTitle = "Status"
    let sectionDescription = "Current attendance status."

    private let repository: AttendanceRepositoryProtocol
    private let workplaceId: UUID

    init(repository: AttendanceRepositoryProtocol, workplaceId: UUID) {
        self.repository = repository
        self.workplaceId = workplaceId
        updateStatus()
    }

    var statusText: String { status.rawValue }

    var actionTitle: String {
        status == .onDuty ? "Check Out" : "Check In"
    }

    func updateStatus() {
        do {
            let records = try repository.fetchRecords(for: workplaceId)
            if let latest = records.last, latest.exitTime == nil {
                status = .onDuty
            } else {
                status = .offDuty
            }
            errorMessage = nil
        } catch {
            status = .offDuty
            errorMessage = error.localizedDescription
        }
    }

    func checkIn() throws {
        _ = try repository.checkIn(workplaceId: workplaceId)
        updateStatus()
    }

    func checkOut() throws {
        let records = try repository.fetchRecords(for: workplaceId)
        if let latest = records.last, latest.exitTime == nil {
            try repository.checkOut(latest)
        }
        updateStatus()
    }

    func performPrimaryAction() throws {
        if status == .onDuty {
            try checkOut()
        } else {
            try checkIn()
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
