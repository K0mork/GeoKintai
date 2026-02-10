import CryptoKit
import Foundation

public enum IntegrityHashService {
    public static func hashCorrection(_ correction: AttendanceCorrection) -> String {
        let payload = [
            correction.id.uuidString,
            correction.attendanceRecordId.uuidString,
            correction.reason,
            iso8601(correction.before.entryTime),
            iso8601Optional(correction.before.exitTime),
            iso8601(correction.after.entryTime),
            iso8601Optional(correction.after.exitTime),
            iso8601(correction.correctedAt)
        ].joined(separator: "|")

        return sha256Hex(payload)
    }

    public static func verifyCorrection(_ correction: AttendanceCorrection, hash: String) -> Bool {
        hashCorrection(correction) == hash
    }

    public static func hashLocationProof(_ proof: LocationProof) -> String {
        let payload = [
            proof.id.uuidString,
            proof.workplaceId.uuidString,
            proof.attendanceRecordId.uuidString,
            iso8601(proof.timestamp),
            normalizedDouble(proof.latitude),
            normalizedDouble(proof.longitude),
            normalizedDouble(proof.horizontalAccuracy),
            proof.reason.rawValue
        ].joined(separator: "|")

        return sha256Hex(payload)
    }

    public static func verifyLocationProof(_ proof: LocationProof, hash: String) -> Bool {
        hashLocationProof(proof) == hash
    }

    private static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func iso8601Optional(_ date: Date?) -> String {
        guard let date else {
            return "nil"
        }
        return iso8601(date)
    }

    private static func normalizedDouble(_ value: Double) -> String {
        String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
