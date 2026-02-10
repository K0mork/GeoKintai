import Foundation
import SwiftUI
import GeoKintaiCore

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var workplaces: [Workplace] = []
    @Published private(set) var attendanceRecords: [AttendanceRecord] = []
    @Published private(set) var corrections: [AttendanceCorrection] = []
    @Published private(set) var proofs: [LocationProof] = []
    @Published private(set) var logs: [LogEvent] = []

    @Published var selectedWorkplaceId: UUID?
    @Published var permissionStatus: LocationPermissionStatus = .notDetermined {
        didSet { evaluatePermission() }
    }
    @Published private(set) var permissionDecision = PermissionDecision(
        shouldRunAutoRecording: false,
        guidance: .requestAlwaysAuthorization
    )
    @Published private(set) var lastExport: ExportPayload?
    @Published var lastErrorMessage: String?

    private let persistence: PersistenceController
    private let permissionUseCase: PermissionUseCase
    private let exportService: ExportService
    private let logger: LoggingService
    private let clock: any VerificationClock

    init(
        persistence: PersistenceController = PersistenceController(),
        permissionUseCase: PermissionUseCase = PermissionUseCase(),
        clock: any VerificationClock = SystemVerificationClock()
    ) {
        self.persistence = persistence
        self.permissionUseCase = permissionUseCase
        self.clock = clock
        self.exportService = ExportService(clock: clock)
        self.logger = LoggingService(clock: clock)
        bootstrapIfNeeded()
        evaluatePermission()
        reloadAll()
    }

    func addWorkplace(name: String, latitudeText: String, longitudeText: String, radiusText: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            lastErrorMessage = "仕事場名を入力してください。"
            return
        }

        guard let latitude = Double(latitudeText), let longitude = Double(longitudeText) else {
            lastErrorMessage = "緯度・経度は数値で入力してください。"
            return
        }

        let radius: Double
        if radiusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            radius = DomainDefaults.defaultWorkplaceRadiusMeters
        } else if let parsed = Double(radiusText), parsed > 0 {
            radius = parsed
        } else {
            lastErrorMessage = "半径は正の数値で入力してください。"
            return
        }

        let workplace = Workplace(
            name: normalizedName,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            monitoringEnabled: true
        )
        persistence.workplaces.save(workplace)
        lastErrorMessage = nil
        reloadAll()
    }

    func deleteWorkplace(id: UUID) {
        persistence.workplaces.delete(id: id)
        if selectedWorkplaceId == id {
            selectedWorkplaceId = nil
        }
        reloadAll()
    }

    func toggleMonitoring(id: UUID) {
        guard var workplace = persistence.workplaces.fetchBy(id: id) else {
            return
        }

        workplace.monitoringEnabled.toggle()
        persistence.workplaces.save(workplace)
        reloadAll()
    }

    func setMonitoring(id: UUID, enabled: Bool) {
        guard var workplace = persistence.workplaces.fetchBy(id: id) else {
            return
        }

        workplace.monitoringEnabled = enabled
        persistence.workplaces.save(workplace)
        reloadAll()
    }

    func simulateCheckIn() {
        guard let workplace = selectedWorkplace else {
            lastErrorMessage = "仕事場を選択してください。"
            return
        }

        guard workplace.monitoringEnabled else {
            lastErrorMessage = "選択中の仕事場は監視無効です。"
            return
        }

        guard permissionDecision.shouldRunAutoRecording else {
            handlePermissionBlocked()
            return
        }

        let now = clock.now
        let record = persistence.attendance.createOpenRecord(
            workplaceId: workplace.id,
            entryTime: now
        )
        let proof = LocationProof(
            workplaceId: workplace.id,
            attendanceRecordId: record.id,
            timestamp: now,
            latitude: workplace.latitude,
            longitude: workplace.longitude,
            horizontalAccuracy: 5,
            reason: .entryTrigger
        )
        persistence.locationProofs.append(proof)
        logger.log(.didEnterRegion(workplaceId: workplace.id))
        logger.log(.stayConfirmed(recordId: record.id))
        lastErrorMessage = nil
        reloadAll()
    }

    func simulateCheckOut() {
        guard let workplace = selectedWorkplace else {
            lastErrorMessage = "仕事場を選択してください。"
            return
        }

        guard permissionDecision.shouldRunAutoRecording else {
            handlePermissionBlocked()
            return
        }

        let now = clock.now
        guard let closed = persistence.attendance.closeOpenRecord(
            workplaceId: workplace.id,
            exitTime: now
        ) else {
            lastErrorMessage = "勤務中レコードがありません。"
            return
        }

        let proof = LocationProof(
            workplaceId: workplace.id,
            attendanceRecordId: closed.id,
            timestamp: now,
            latitude: workplace.latitude,
            longitude: workplace.longitude,
            horizontalAccuracy: 7,
            reason: .exitCheck
        )
        persistence.locationProofs.append(proof)
        logger.log(.didExitRegion(workplaceId: workplace.id))
        logger.log(.exitConfirmed(recordId: closed.id))
        lastErrorMessage = nil
        reloadAll()
    }

    func addSampleCorrection() {
        guard let latestRecord = attendanceRecords.first else {
            lastErrorMessage = "修正対象の勤務レコードがありません。"
            return
        }

        let before = AttendanceSnapshot(
            entryTime: latestRecord.entryTime,
            exitTime: latestRecord.exitTime
        )
        let after = AttendanceSnapshot(
            entryTime: latestRecord.entryTime.addingTimeInterval(60),
            exitTime: latestRecord.exitTime
        )

        let draft = AttendanceCorrection(
            attendanceRecordId: latestRecord.id,
            reason: "手動修正サンプル",
            before: before,
            after: after,
            correctedAt: clock.now,
            integrityHash: ""
        )

        let correction = AttendanceCorrection(
            id: draft.id,
            attendanceRecordId: draft.attendanceRecordId,
            reason: draft.reason,
            before: draft.before,
            after: draft.after,
            correctedAt: draft.correctedAt,
            integrityHash: IntegrityHashService.hashCorrection(draft)
        )
        persistence.corrections.append(correction)
        reloadAll()
    }

    func exportCSV() {
        export(format: .csv)
    }

    func exportPDF() {
        export(format: .pdf)
    }

    private var selectedWorkplace: Workplace? {
        guard let selectedWorkplaceId else {
            return nil
        }
        return persistence.workplaces.fetchBy(id: selectedWorkplaceId)
    }

    private func bootstrapIfNeeded() {
        guard persistence.workplaces.fetchAll().isEmpty else {
            return
        }

        let defaultWorkplace = Workplace(
            name: "本社",
            latitude: 35.681236,
            longitude: 139.767125,
            radius: DomainDefaults.defaultWorkplaceRadiusMeters,
            monitoringEnabled: true
        )
        persistence.workplaces.save(defaultWorkplace)
        selectedWorkplaceId = defaultWorkplace.id
    }

    private func reloadAll() {
        workplaces = persistence.workplaces.fetchAll().sorted { $0.name < $1.name }
        attendanceRecords = persistence.attendance.fetchAll().sorted { $0.entryTime > $1.entryTime }
        corrections = persistence.corrections.fetchAll().sorted { $0.correctedAt > $1.correctedAt }
        proofs = persistence.locationProofs.fetchAll().sorted { $0.timestamp > $1.timestamp }
        logs = logger.allEvents()

        if selectedWorkplaceId == nil {
            selectedWorkplaceId = workplaces.first?.id
        }
    }

    private func evaluatePermission() {
        permissionDecision = permissionUseCase.evaluate(
            status: permissionStatus,
            requiresBackgroundRecording: true
        )
    }

    private func handlePermissionBlocked() {
        switch permissionDecision.guidance {
        case .requestAlwaysAuthorization:
            lastErrorMessage = "常時許可が必要です。権限を更新してください。"
        case .openSettings:
            lastErrorMessage = "位置権限が不足しています。設定アプリから変更してください。"
        case .none:
            lastErrorMessage = "自動記録を開始できません。"
        }

        logger.log(.failure(type: .permissionInsufficient, detail: lastErrorMessage ?? "permission blocked"))
        reloadAll()
    }

    private func export(format: ExportFormat) {
        do {
            let payload = try exportService.buildExport(
                format: format,
                attendance: persistence.attendance.fetchAll(),
                corrections: persistence.corrections.fetchAll(),
                proofs: persistence.locationProofs.fetchAll()
            )
            if ExportService.verify(content: payload.content, hash: payload.integrityHash) {
                lastExport = payload
                lastErrorMessage = nil
            } else {
                lastErrorMessage = "エクスポート整合性の検証に失敗しました。"
            }
        } catch let error as ExportError {
            lastErrorMessage = error.userMessage
        } catch {
            lastErrorMessage = "出力に失敗しました: \(error.localizedDescription)"
        }
    }
}
