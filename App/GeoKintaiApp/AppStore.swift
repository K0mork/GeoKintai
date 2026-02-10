import Foundation
import SwiftUI
import UIKit
import CoreLocation
import GeoKintaiCore

protocol PersistenceWritePerformer {
    func perform<T>(_ action: () -> T) throws -> T
}

struct DefaultPersistenceWritePerformer: PersistenceWritePerformer {
    func perform<T>(_ action: () -> T) throws -> T {
        action()
    }
}

protocol URLHandling {
    @discardableResult
    func open(_ url: URL) -> Bool
}

struct UIApplicationURLHandler: URLHandling {
    @discardableResult
    func open(_ url: URL) -> Bool {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var workplaces: [Workplace] = []
    @Published private(set) var attendanceRecords: [AttendanceRecord] = []
    @Published private(set) var corrections: [AttendanceCorrection] = []
    @Published private(set) var proofs: [LocationProof] = []
    @Published private(set) var logs: [LogEvent] = []
    @Published private(set) var monitoredWorkplaceIds: Set<UUID> = []
    @Published private(set) var corruptedCorrectionIds: Set<UUID> = []

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
    private let failureHandlingUseCase: FailureHandlingUseCase
    private let clock: any VerificationClock
    private let regionMonitoringSyncService: RegionMonitoringSyncService
    private let backgroundLocationClient: any BackgroundLocationClient
    private let attendanceFlowCoordinator: AttendanceFlowCoordinator
    private let writePerformer: any PersistenceWritePerformer
    private let urlHandler: any URLHandling
    private var pendingStayWorkplaceIds: Set<UUID> = []
    private var pendingExitWorkplaceIds: Set<UUID> = []

    init(
        persistence: PersistenceController = PersistenceController(),
        permissionUseCase: PermissionUseCase = PermissionUseCase(),
        clock: any VerificationClock = SystemVerificationClock(),
        regionMonitoringSyncService: RegionMonitoringSyncService = RegionMonitoringSyncService(
            regionMonitor: InMemoryRegionMonitor()
        ),
        backgroundLocationClient: any BackgroundLocationClient = NoopBackgroundLocationClient(),
        failureHandlingUseCase: FailureHandlingUseCase = FailureHandlingUseCase(),
        writePerformer: any PersistenceWritePerformer = DefaultPersistenceWritePerformer(),
        urlHandler: any URLHandling = UIApplicationURLHandler()
    ) {
        self.persistence = persistence
        self.permissionUseCase = permissionUseCase
        self.clock = clock
        self.exportService = ExportService(clock: clock)
        self.logger = LoggingService(clock: clock)
        self.regionMonitoringSyncService = regionMonitoringSyncService
        self.backgroundLocationClient = backgroundLocationClient
        self.attendanceFlowCoordinator = AttendanceFlowCoordinator(
            attendanceRepository: persistence.attendance,
            proofRepository: persistence.locationProofs,
            clock: clock
        )
        self.failureHandlingUseCase = failureHandlingUseCase
        self.writePerformer = writePerformer
        self.urlHandler = urlHandler
        configureBackgroundLocationCallbacks()
        permissionStatus = backgroundLocationClient.currentPermissionStatus()
        bootstrapIfNeeded()
        evaluatePermission()
        reloadAll()
        syncMonitoringIfNeeded()
        if permissionStatus == .notDetermined {
            backgroundLocationClient.requestAlwaysAuthorization()
        }
    }

    func addWorkplace(name: String, latitudeText: String, longitudeText: String, radiusText: String) {
        guard let input = validateWorkplaceInput(
            name: name,
            latitudeText: latitudeText,
            longitudeText: longitudeText,
            radiusText: radiusText
        ) else {
            return
        }

        let workplace = Workplace(
            name: input.name,
            latitude: input.latitude,
            longitude: input.longitude,
            radius: input.radius,
            monitoringEnabled: true
        )
        guard performWriteVoid({ persistence.workplaces.save(workplace) }) else {
            return
        }
        lastErrorMessage = nil
        reloadAll()
        syncMonitoringIfNeeded()
    }

    func updateWorkplace(id: UUID, name: String, latitudeText: String, longitudeText: String, radiusText: String) {
        guard var workplace = persistence.workplaces.fetchBy(id: id) else {
            lastErrorMessage = "対象の仕事場が見つかりません。"
            return
        }

        guard let input = validateWorkplaceInput(
            name: name,
            latitudeText: latitudeText,
            longitudeText: longitudeText,
            radiusText: radiusText
        ) else {
            return
        }

        workplace.name = input.name
        workplace.latitude = input.latitude
        workplace.longitude = input.longitude
        workplace.radius = input.radius

        guard performWriteVoid({ persistence.workplaces.save(workplace) }) else {
            return
        }
        lastErrorMessage = nil
        reloadAll()
        syncMonitoringIfNeeded()
    }

    func deleteWorkplace(id: UUID) {
        guard performWriteVoid({ persistence.workplaces.delete(id: id) }) else {
            return
        }
        if selectedWorkplaceId == id {
            selectedWorkplaceId = nil
        }
        reloadAll()
        syncMonitoringIfNeeded()
    }

    func toggleMonitoring(id: UUID) {
        guard var workplace = persistence.workplaces.fetchBy(id: id) else {
            return
        }

        workplace.monitoringEnabled.toggle()
        guard performWriteVoid({ persistence.workplaces.save(workplace) }) else {
            return
        }
        reloadAll()
        syncMonitoringIfNeeded()
    }

    func setMonitoring(id: UUID, enabled: Bool) {
        guard var workplace = persistence.workplaces.fetchBy(id: id) else {
            return
        }

        workplace.monitoringEnabled = enabled
        guard performWriteVoid({ persistence.workplaces.save(workplace) }) else {
            return
        }
        reloadAll()
        syncMonitoringIfNeeded()
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
        guard let record = performWrite({
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
            return record
        }) else {
            return
        }
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
        let closeResult: AttendanceRecord?? = performWrite({
            persistence.attendance.closeOpenRecord(
                workplaceId: workplace.id,
                exitTime: now
            )
        })
        guard let wrappedClosed = closeResult else {
            return
        }
        guard let closed = wrappedClosed else {
            lastErrorMessage = "勤務中レコードがありません。"
            return
        }

        guard performWriteVoid({
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
        }) else {
            return
        }
        logger.log(.didExitRegion(workplaceId: workplace.id))
        logger.log(.exitConfirmed(recordId: closed.id))
        lastErrorMessage = nil
        reloadAll()
    }

    func addManualCorrection(
        recordId: UUID,
        reason: String,
        correctedEntryTime: Date,
        correctedExitTime: Date?
    ) {
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            lastErrorMessage = "修正理由を入力してください。"
            return
        }

        if let correctedExitTime, correctedExitTime < correctedEntryTime {
            lastErrorMessage = "退勤時刻は出勤時刻以降にしてください。"
            return
        }

        guard let sourceRecord = persistence.attendance.fetchAll().first(where: { $0.id == recordId }) else {
            lastErrorMessage = "修正対象の勤務レコードが見つかりません。"
            return
        }

        let before = AttendanceSnapshot(
            entryTime: sourceRecord.entryTime,
            exitTime: sourceRecord.exitTime
        )
        let after = AttendanceSnapshot(
            entryTime: correctedEntryTime,
            exitTime: correctedExitTime
        )

        let draft = AttendanceCorrection(
            attendanceRecordId: sourceRecord.id,
            reason: normalizedReason,
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

        guard performWriteVoid({ persistence.corrections.append(correction) }) else {
            return
        }

        lastErrorMessage = nil
        reloadAll()
    }

    func addSampleCorrection() {
        guard let latestRecord = attendanceRecords.first else {
            lastErrorMessage = "修正対象の勤務レコードがありません。"
            return
        }
        addManualCorrection(
            recordId: latestRecord.id,
            reason: "手動修正サンプル",
            correctedEntryTime: latestRecord.entryTime.addingTimeInterval(60),
            correctedExitTime: latestRecord.exitTime
        )
    }

    func exportCSV() {
        export(format: .csv)
    }

    func exportPDF() {
        export(format: .pdf)
    }

    func openAppSettings() {
        guard permissionDecision.guidance == .openSettings else {
            return
        }
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        _ = urlHandler.open(url)
    }

    func workplaceName(for id: UUID) -> String {
        workplaces.first(where: { $0.id == id })?.name ?? id.uuidString
    }

    private var selectedWorkplace: Workplace? {
        guard let selectedWorkplaceId else {
            return nil
        }
        return persistence.workplaces.fetchBy(id: selectedWorkplaceId)
    }

    private func configureBackgroundLocationCallbacks() {
        backgroundLocationClient.onAuthorizationChanged = { [weak self] status in
            self?.permissionStatus = status
        }

        backgroundLocationClient.onDidEnterRegion = { [weak self] workplaceId in
            self?.handleDidEnterRegion(workplaceId: workplaceId)
        }

        backgroundLocationClient.onDidExitRegion = { [weak self] workplaceId in
            self?.handleDidExitRegion(workplaceId: workplaceId)
        }

        backgroundLocationClient.onDidDetermineState = { [weak self] workplaceId, isInside in
            guard isInside else {
                return
            }
            self?.handleDidEnterRegion(workplaceId: workplaceId)
        }

        backgroundLocationClient.onLocationUpdate = { [weak self] sample in
            self?.handleLocationUpdate(sample)
        }

        backgroundLocationClient.onLocationError = { [weak self] message in
            self?.handleLocationUnavailable(message)
        }
    }

    private func handleDidEnterRegion(workplaceId: UUID) {
        guard permissionDecision.shouldRunAutoRecording else {
            return
        }
        guard !pendingStayWorkplaceIds.contains(workplaceId) else {
            return
        }
        guard persistence.attendance.fetchOpenRecord(workplaceId: workplaceId) == nil else {
            return
        }
        guard let workplace = persistence.workplaces.fetchBy(id: workplaceId), workplace.monitoringEnabled else {
            return
        }

        pendingStayWorkplaceIds.insert(workplaceId)
        attendanceFlowCoordinator.handleDidEnter(workplace: workplace)
        logger.log(.didEnterRegion(workplaceId: workplaceId))
        updateLocationUpdateSubscription()
        reloadAll()
    }

    private func handleDidExitRegion(workplaceId: UUID) {
        guard permissionDecision.shouldRunAutoRecording else {
            return
        }
        guard !pendingExitWorkplaceIds.contains(workplaceId) else {
            return
        }
        guard persistence.attendance.fetchOpenRecord(workplaceId: workplaceId) != nil else {
            return
        }
        guard let workplace = persistence.workplaces.fetchBy(id: workplaceId), workplace.monitoringEnabled else {
            return
        }

        pendingExitWorkplaceIds.insert(workplaceId)
        attendanceFlowCoordinator.handleDidExit(workplace: workplace)
        logger.log(.didExitRegion(workplaceId: workplaceId))
        updateLocationUpdateSubscription()
        reloadAll()
    }

    private func handleLocationUpdate(_ sample: LocationCoordinateSample) {
        guard permissionDecision.shouldRunAutoRecording else {
            return
        }

        let activeIds = pendingStayWorkplaceIds.union(pendingExitWorkplaceIds)
        guard !activeIds.isEmpty else {
            updateLocationUpdateSubscription()
            return
        }

        for workplaceId in activeIds {
            guard let workplace = persistence.workplaces.fetchBy(id: workplaceId) else {
                pendingStayWorkplaceIds.remove(workplaceId)
                pendingExitWorkplaceIds.remove(workplaceId)
                attendanceFlowCoordinator.cancel(workplaceId: workplaceId)
                continue
            }

            let distance = distanceFromCenterMeters(sample: sample, workplace: workplace)
            let outcome = attendanceFlowCoordinator.handleLocationUpdate(
                workplace: workplace,
                distanceFromCenterMeters: distance
            )
            handleCoordinatorOutcome(outcome, workplaceId: workplaceId)
        }

        updateLocationUpdateSubscription()
        reloadAll()
    }

    private func handleCoordinatorOutcome(_ outcome: AttendanceFlowCoordinator.Outcome, workplaceId: UUID) {
        switch outcome {
        case .none:
            break
        case .entryConfirmed(let recordId):
            pendingStayWorkplaceIds.remove(workplaceId)
            logger.log(.stayConfirmed(recordId: recordId))
            lastErrorMessage = nil
        case .entryCancelled:
            pendingStayWorkplaceIds.remove(workplaceId)
        case .exitConfirmed(let recordId):
            pendingExitWorkplaceIds.remove(workplaceId)
            logger.log(.exitConfirmed(recordId: recordId))
            lastErrorMessage = nil
        }
    }

    private func distanceFromCenterMeters(sample: LocationCoordinateSample, workplace: Workplace) -> Double {
        let current = CLLocation(latitude: sample.latitude, longitude: sample.longitude)
        let center = CLLocation(latitude: workplace.latitude, longitude: workplace.longitude)
        return current.distance(from: center)
    }

    private func updateLocationUpdateSubscription() {
        guard permissionDecision.shouldRunAutoRecording else {
            backgroundLocationClient.stopUpdatingLocation()
            return
        }

        let hasPendingVerification = !pendingStayWorkplaceIds.isEmpty || !pendingExitWorkplaceIds.isEmpty
        if hasPendingVerification {
            backgroundLocationClient.startUpdatingLocation()
        } else {
            backgroundLocationClient.stopUpdatingLocation()
        }
    }

    private func handleLocationUnavailable(_ detail: String) {
        let action = failureHandlingUseCase.handle(.locationUnavailable)
        lastErrorMessage = action.userMessage
        logger.log(.failure(type: .locationUnavailable, detail: detail))
        reloadAll()
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
        guard performWriteVoid({ persistence.workplaces.save(defaultWorkplace) }) else {
            return
        }
        selectedWorkplaceId = defaultWorkplace.id
    }

    private func reloadAll() {
        workplaces = persistence.workplaces.fetchAll().sorted { $0.name < $1.name }
        attendanceRecords = persistence.attendance.fetchAll().sorted { $0.entryTime > $1.entryTime }
        corrections = persistence.corrections.fetchAll().sorted { $0.correctedAt > $1.correctedAt }
        proofs = persistence.locationProofs.fetchAll().sorted { $0.timestamp > $1.timestamp }
        logs = logger.allEvents()
        refreshCorrectionIntegrityMismatches()

        if selectedWorkplaceId == nil {
            selectedWorkplaceId = workplaces.first?.id
        }
    }

    private func refreshCorrectionIntegrityMismatches() {
        corruptedCorrectionIds = Set(
            corrections
                .filter { !IntegrityHashService.verifyCorrection($0, hash: $0.integrityHash) }
                .map(\.id)
        )
    }

    private func evaluatePermission() {
        permissionDecision = permissionUseCase.evaluate(
            status: permissionStatus,
            requiresBackgroundRecording: true
        )
        if !permissionDecision.shouldRunAutoRecording {
            pendingStayWorkplaceIds.removeAll()
            pendingExitWorkplaceIds.removeAll()
            attendanceFlowCoordinator.cancelAll()
            backgroundLocationClient.stopUpdatingLocation()
        }
        syncMonitoringIfNeeded()
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

    private func syncMonitoringIfNeeded() {
        let previousIds = monitoredWorkplaceIds
        let syncResult = regionMonitoringSyncService.sync(
            workplaces: persistence.workplaces.fetchAll(),
            allowMonitoring: permissionDecision.shouldRunAutoRecording
        )
        let synchronizedIds = syncResult.monitoredWorkplaceIds
        monitoredWorkplaceIds = synchronizedIds

        let removedIds = previousIds.subtracting(synchronizedIds)
        for workplaceId in removedIds {
            pendingStayWorkplaceIds.remove(workplaceId)
            pendingExitWorkplaceIds.remove(workplaceId)
            attendanceFlowCoordinator.cancel(workplaceId: workplaceId)
        }

        if permissionDecision.shouldRunAutoRecording {
            let stateRequestIds = synchronizedIds
                .subtracting(previousIds)
                .union(syncResult.changedWorkplaceIds)
            for workplaceId in stateRequestIds {
                backgroundLocationClient.requestState(for: workplaceId)
            }
        }

        updateLocationUpdateSubscription()
    }

    @discardableResult
    private func performWrite<T>(_ operation: () -> T) -> T? {
        do {
            return try writePerformer.perform(operation)
        } catch {
            handlePersistenceWriteFailure(error)
            return nil
        }
    }

    private func handlePersistenceWriteFailure(_ error: Error) {
        let action = failureHandlingUseCase.handle(.persistenceWriteFailed)
        lastErrorMessage = action.userMessage
        logger.log(.failure(type: .persistenceWriteFailed, detail: error.localizedDescription))

        if action.shouldPreserveExistingData {
            reloadAll()
        }
    }

    private func performWriteVoid(_ operation: () -> Void) -> Bool {
        performWrite(operation) != nil
    }

    private struct ValidatedWorkplaceInput {
        let name: String
        let latitude: Double
        let longitude: Double
        let radius: Double
    }

    private func validateWorkplaceInput(
        name: String,
        latitudeText: String,
        longitudeText: String,
        radiusText: String
    ) -> ValidatedWorkplaceInput? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            lastErrorMessage = "仕事場名を入力してください。"
            return nil
        }

        let normalizedLatitudeText = latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLongitudeText = longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let latitude = Double(normalizedLatitudeText), let longitude = Double(normalizedLongitudeText) else {
            lastErrorMessage = "緯度・経度は数値で入力してください。"
            return nil
        }

        guard (-90...90).contains(latitude) else {
            lastErrorMessage = "緯度は -90 〜 90 の範囲で入力してください。"
            return nil
        }

        guard (-180...180).contains(longitude) else {
            lastErrorMessage = "経度は -180 〜 180 の範囲で入力してください。"
            return nil
        }

        let normalizedRadiusText = radiusText.trimmingCharacters(in: .whitespacesAndNewlines)
        let radius: Double
        if normalizedRadiusText.isEmpty {
            radius = DomainDefaults.defaultWorkplaceRadiusMeters
        } else if let parsed = Double(normalizedRadiusText), parsed > 0 {
            radius = parsed
        } else {
            lastErrorMessage = "半径は正の数値で入力してください。"
            return nil
        }

        return ValidatedWorkplaceInput(
            name: normalizedName,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
    }
}
