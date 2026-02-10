import Foundation

public final class PersistenceController {
    public private(set) var workplaces: WorkplaceRepository
    public private(set) var attendance: AttendanceRepository
    public private(set) var corrections: AttendanceCorrectionRepository
    public private(set) var locationProofs: LocationProofRepository

    private let storeURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(storeURL: URL? = nil) {
        self.storeURL = storeURL

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let snapshot = Self.loadSnapshot(from: storeURL, decoder: decoder) ?? Snapshot()
        workplaces = WorkplaceRepository(initialWorkplaces: snapshot.workplaces)
        attendance = AttendanceRepository(initialRecords: snapshot.attendance)
        corrections = AttendanceCorrectionRepository(initialCorrections: snapshot.corrections)
        locationProofs = LocationProofRepository(initialProofs: snapshot.locationProofs)
        bindChangeHandlers()
    }

    public static func defaultStoreURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory
            .appendingPathComponent("GeoKintai", isDirectory: true)
            .appendingPathComponent("persistence.json")
    }

    public func reset() {
        workplaces = WorkplaceRepository()
        attendance = AttendanceRepository()
        corrections = AttendanceCorrectionRepository()
        locationProofs = LocationProofRepository()
        bindChangeHandlers()
        persistIfNeeded()
    }

    private func bindChangeHandlers() {
        workplaces.onChange = { [weak self] _ in
            self?.persistIfNeeded()
        }
        attendance.onChange = { [weak self] _ in
            self?.persistIfNeeded()
        }
        corrections.onChange = { [weak self] _ in
            self?.persistIfNeeded()
        }
        locationProofs.onChange = { [weak self] _ in
            self?.persistIfNeeded()
        }
    }

    private func persistIfNeeded() {
        guard let storeURL else {
            return
        }

        let snapshot = Snapshot(
            workplaces: workplaces.fetchAll(),
            attendance: attendance.fetchAll(),
            corrections: corrections.fetchAll(),
            locationProofs: locationProofs.fetchAll()
        )

        do {
            let directoryURL = storeURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try encoder.encode(snapshot)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            // 永続化失敗時は既存メモリデータを優先して処理継続する。
        }
    }

    private static func loadSnapshot(from storeURL: URL?, decoder: JSONDecoder) -> Snapshot? {
        guard let storeURL, FileManager.default.fileExists(atPath: storeURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: storeURL)
            return try decoder.decode(Snapshot.self, from: data)
        } catch {
            return nil
        }
    }

    private struct Snapshot: Codable {
        var workplaces: [Workplace]
        var attendance: [AttendanceRecord]
        var corrections: [AttendanceCorrection]
        var locationProofs: [LocationProof]

        init(
            workplaces: [Workplace] = [],
            attendance: [AttendanceRecord] = [],
            corrections: [AttendanceCorrection] = [],
            locationProofs: [LocationProof] = []
        ) {
            self.workplaces = workplaces
            self.attendance = attendance
            self.corrections = corrections
            self.locationProofs = locationProofs
        }
    }
}
