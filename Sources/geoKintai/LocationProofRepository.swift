import Foundation

public final class LocationProofRepository {
    private var proofs: [LocationProof]
    public var onChange: (([LocationProof]) -> Void)?

    public init(
        initialProofs: [LocationProof] = [],
        onChange: (([LocationProof]) -> Void)? = nil
    ) {
        self.proofs = initialProofs
        self.onChange = onChange
    }

    public func append(_ proof: LocationProof) {
        proofs.append(proof)
        onChange?(proofs)
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
