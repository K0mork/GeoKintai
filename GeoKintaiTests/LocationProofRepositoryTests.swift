import XCTest
import CoreLocation
@testable import GeoKintai

@MainActor
final class LocationProofRepositoryTests: XCTestCase {
    var controller: PersistenceController!
    var repository: LocationProofRepository!
    var recordId: UUID!

    override func setUp() async throws {
        controller = PersistenceController(inMemory: true)
        repository = LocationProofRepository(context: controller.viewContext)
        recordId = UUID()
    }

    func testAddSingleProof() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            altitude: 10,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            timestamp: Date()
        )

        let proof = try repository.add(
            recordId: recordId,
            location: location,
            reason: .entryTrigger
        )

        XCTAssertEqual(proof.recordId, recordId)
        XCTAssertEqual(proof.latitude, 35.6812, accuracy: 0.0001)
        XCTAssertEqual(proof.longitude, 139.7671, accuracy: 0.0001)
        XCTAssertEqual(proof.accuracy, 5)
        XCTAssertEqual(proof.altitude?.doubleValue, 10)
        XCTAssertEqual(proof.reason, "EntryTrigger")
    }

    func testAddBatchProofs() throws {
        let locations = [
            CLLocation(latitude: 35.0, longitude: 139.0),
            CLLocation(latitude: 35.1, longitude: 139.1),
            CLLocation(latitude: 35.2, longitude: 139.2)
        ]

        try repository.addBatch(recordId: recordId, locations: locations, reason: .stayCheck)

        let proofs = try repository.fetchProofs(for: recordId)
        XCTAssertEqual(proofs.count, 3)
        XCTAssertEqual(proofs[0].reason, "StayCheck")
    }

    func testFetchProofsForRecord() throws {
        let location1 = CLLocation(latitude: 35.0, longitude: 139.0)
        let location2 = CLLocation(latitude: 35.1, longitude: 139.1)
        let otherRecordId = UUID()

        try repository.add(recordId: recordId, location: location1, reason: .entryTrigger)
        try repository.add(recordId: recordId, location: location2, reason: .stayCheck)
        try repository.add(recordId: otherRecordId, location: location1, reason: .exitCheck)

        let proofs = try repository.fetchProofs(for: recordId)
        XCTAssertEqual(proofs.count, 2)

        let otherProofs = try repository.fetchProofs(for: otherRecordId)
        XCTAssertEqual(otherProofs.count, 1)
        XCTAssertEqual(otherProofs[0].reason, "ExitCheck")
    }

    func testProofWithNegativeAltitudeAndSpeed() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            altitude: -1,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            course: -1,
            speed: -1,
            timestamp: Date()
        )

        let proof = try repository.add(recordId: recordId, location: location, reason: .stayCheck)

        XCTAssertNil(proof.altitude)
        XCTAssertNil(proof.speed)
    }
}
