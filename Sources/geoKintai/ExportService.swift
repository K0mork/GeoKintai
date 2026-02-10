import CryptoKit
import Foundation

public enum ExportFormat: Equatable {
    case csv
    case pdf
}

public struct ExportPayload: Equatable {
    public let format: ExportFormat
    public let content: String
    public let generatedAt: Date
    public let integrityHash: String

    public init(format: ExportFormat, content: String, generatedAt: Date, integrityHash: String) {
        self.format = format
        self.content = content
        self.generatedAt = generatedAt
        self.integrityHash = integrityHash
    }
}

public enum ExportError: Error, Equatable {
    case noData

    public var userMessage: String {
        switch self {
        case .noData:
            return "出力対象データがありません。条件を変更して再試行してください。"
        }
    }
}

public struct ExportService {
    private let clock: VerificationClock

    public init(clock: VerificationClock) {
        self.clock = clock
    }

    public func buildExport(
        format: ExportFormat,
        attendance: [AttendanceRecord],
        corrections: [AttendanceCorrection],
        proofs: [LocationProof]
    ) throws -> ExportPayload {
        guard !attendance.isEmpty || !corrections.isEmpty || !proofs.isEmpty else {
            throw ExportError.noData
        }

        let generatedAt = clock.now
        let contentWithoutHash: String

        switch format {
        case .csv:
            contentWithoutHash = csvContent(
                attendance: attendance,
                corrections: corrections,
                proofs: proofs,
                generatedAt: generatedAt
            )
        case .pdf:
            contentWithoutHash = pdfLikeContent(
                attendance: attendance,
                corrections: corrections,
                proofs: proofs,
                generatedAt: generatedAt
            )
        }

        let integrityHash = sha256Hex(contentWithoutHash)
        let content = contentWithoutHash + "\nintegrity_hash,\(integrityHash)"
        return ExportPayload(format: format, content: content, generatedAt: generatedAt, integrityHash: integrityHash)
    }

    public static func verify(content: String, hash: String) -> Bool {
        let filteredLines = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("integrity_hash,") }
            .map(String.init)
        let normalized = filteredLines.joined(separator: "\n")
        return sha256Hex(normalized) == hash
    }

    private func csvContent(
        attendance: [AttendanceRecord],
        corrections: [AttendanceCorrection],
        proofs: [LocationProof],
        generatedAt: Date
    ) -> String {
        var lines: [String] = []
        lines.append("generated_at,\(iso8601(generatedAt))")
        lines.append("format,csv")
        lines.append("[attendance]")
        lines.append("attendance_id,workplace_id,entry_time,exit_time")
        lines.append(contentsOf: attendance.map { record in
            "\(record.id.uuidString),\(record.workplaceId.uuidString),\(iso8601(record.entryTime)),\(iso8601Optional(record.exitTime))"
        })

        lines.append("[corrections]")
        lines.append("correction_id,attendance_id,reason,before_entry,before_exit,after_entry,after_exit,corrected_at,record_hash")
        lines.append(contentsOf: corrections.map { correction in
            "\(correction.id.uuidString),\(correction.attendanceRecordId.uuidString),\(sanitize(correction.reason)),\(iso8601(correction.before.entryTime)),\(iso8601Optional(correction.before.exitTime)),\(iso8601(correction.after.entryTime)),\(iso8601Optional(correction.after.exitTime)),\(iso8601(correction.correctedAt)),\(correction.integrityHash)"
        })

        lines.append("[proofs]")
        lines.append("proof_id,attendance_id,workplace_id,timestamp,latitude,longitude,horizontal_accuracy,reason")
        lines.append(contentsOf: proofs.map { proof in
            "\(proof.id.uuidString),\(proof.attendanceRecordId.uuidString),\(proof.workplaceId.uuidString),\(iso8601(proof.timestamp)),\(proof.latitude),\(proof.longitude),\(proof.horizontalAccuracy),\(proof.reason.rawValue)"
        })

        return lines.joined(separator: "\n")
    }

    private func pdfLikeContent(
        attendance: [AttendanceRecord],
        corrections: [AttendanceCorrection],
        proofs: [LocationProof],
        generatedAt: Date
    ) -> String {
        [
            "PDF_EXPORT",
            "generated_at,\(iso8601(generatedAt))",
            "attendance_count,\(attendance.count)",
            "correction_count,\(corrections.count)",
            "proof_count,\(proofs.count)"
        ].joined(separator: "\n")
    }

    private func sanitize(_ input: String) -> String {
        input.replacingOccurrences(of: ",", with: " ")
    }

    private func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func iso8601Optional(_ date: Date?) -> String {
        guard let date else { return "" }
        return iso8601(date)
    }

    private static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256Hex(_ input: String) -> String {
        Self.sha256Hex(input)
    }
}
