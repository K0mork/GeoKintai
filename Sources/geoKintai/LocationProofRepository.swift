import Foundation

public final class LocationProofRepository {
    private var proofs: [LocationProof]

    public init(initialProofs: [LocationProof] = []) {
        self.proofs = initialProofs
    }

    public func append(_ proof: LocationProof) {
        proofs.append(proof)
    }

    public func fetchBy(attendanceRecordId: UUID) -> [LocationProof] {
        proofs
            .filter { $0.attendanceRecordId == attendanceRecordId }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func fetchBy(workplaceId: UUID) -> [LocationProof] {
        proofs
            .filter { $0.workplaceId == workplaceId }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func fetchAll() -> [LocationProof] {
        proofs
    }
}
