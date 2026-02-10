import Foundation

public final class AttendanceFlowCoordinator {
    public enum Outcome: Equatable {
        case none
        case entryConfirmed(recordId: UUID)
        case entryCancelled
        case exitConfirmed(recordId: UUID)
    }

    private let attendanceRepository: AttendanceRepository
    private let proofRepository: LocationProofRepository
    private let clock: VerificationClock

    private var stayVerifiers: [UUID: StayVerifier] = [:]
    private var exitVerifiers: [UUID: ExitVerifier] = [:]

    public init(
        attendanceRepository: AttendanceRepository,
        proofRepository: LocationProofRepository,
        clock: VerificationClock
    ) {
        self.attendanceRepository = attendanceRepository
        self.proofRepository = proofRepository
        self.clock = clock
    }

    public func handleDidEnter(workplace: Workplace) {
        stayVerifiers[workplace.id] = StayVerifier(clock: clock)
    }

    public func handleDidExit(workplace: Workplace) {
        guard attendanceRepository.fetchOpenRecord(workplaceId: workplace.id) != nil else {
            return
        }

        exitVerifiers[workplace.id] = ExitVerifier(clock: clock)
    }

    public func handleLocationUpdate(
        workplace: Workplace,
        distanceFromCenterMeters: Double
    ) -> Outcome {
        if let verifier = stayVerifiers[workplace.id] {
            let decision = verifier.onLocation(
                distanceFromCenterMeters: distanceFromCenterMeters,
                radiusMeters: workplace.radius
            )

            switch decision {
            case .pending:
                return .none
            case .cancelledEarlyExit:
                stayVerifiers[workplace.id] = nil
                return .entryCancelled
            case .confirmed:
                let record = attendanceRepository.createOpenRecord(
                    workplaceId: workplace.id,
                    entryTime: clock.now
                )
                let proof = LocationProof(
                    workplaceId: workplace.id,
                    attendanceRecordId: record.id,
                    timestamp: clock.now,
                    latitude: workplace.latitude,
                    longitude: workplace.longitude,
                    horizontalAccuracy: 5,
                    reason: .stayCheck
                )
                proofRepository.append(proof)
                stayVerifiers[workplace.id] = nil
                return .entryConfirmed(recordId: record.id)
            }
        }

        if let verifier = exitVerifiers[workplace.id] {
            let decision = verifier.onLocation(
                distanceFromCenterMeters: distanceFromCenterMeters,
                radiusMeters: workplace.radius
            )

            switch decision {
            case .pending:
                return .none
            case .confirmed:
                guard let closed = attendanceRepository.closeOpenRecord(
                    workplaceId: workplace.id,
                    exitTime: clock.now
                ) else {
                    exitVerifiers[workplace.id] = nil
                    return .none
                }

                let proof = LocationProof(
                    workplaceId: workplace.id,
                    attendanceRecordId: closed.id,
                    timestamp: clock.now,
                    latitude: workplace.latitude,
                    longitude: workplace.longitude,
                    horizontalAccuracy: 8,
                    reason: .exitCheck
                )
                proofRepository.append(proof)
                exitVerifiers[workplace.id] = nil
                return .exitConfirmed(recordId: closed.id)
            }
        }

        return .none
    }
}
