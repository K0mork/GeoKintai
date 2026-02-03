import SwiftUI
import MapKit

struct HistoryDetailView: View {
    let record: AttendanceRecord
    @FetchRequest private var proofs: FetchedResults<LocationProof>

    init(record: AttendanceRecord) {
        self.record = record
        _proofs = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \LocationProof.timestamp, ascending: true)],
            predicate: NSPredicate(format: "recordId == %@", record.id as CVarArg)
        )
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                LabeledContent("Entry Time") {
                    Text(record.entryTime, style: .time)
                }
                LabeledContent("Exit Time") {
                    if let exitTime = record.exitTime {
                        Text(exitTime, style: .time)
                    } else {
                        Text("In Progress")
                            .foregroundColor(.green)
                    }
                }
                LabeledContent("Duration") {
                    Text(durationText)
                }
                if record.isManual {
                    LabeledContent("Manual Entry") {
                        Image(systemName: "checkmark")
                    }
                }
                if let note = record.note, !note.isEmpty {
                    LabeledContent("Note") {
                        Text(note)
                    }
                }
            }

            Section(header: Text("Location Proofs (\(proofs.count))")) {
                if proofs.isEmpty {
                    Text("No location proofs recorded")
                        .foregroundColor(.secondary)
                } else {
                    Map {
                        ForEach(proofs) { proof in
                            Marker("", coordinate: CLLocationCoordinate2D(
                                latitude: proof.latitude,
                                longitude: proof.longitude
                            ))
                        }
                    }
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())

                    ForEach(proofs) { proof in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(proof.timestamp, style: .time)
                                .font(.headline)
                            Text("Lat: \(proof.latitude, specifier: "%.6f"), Lon: \(proof.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Accuracy: \(proof.accuracy, specifier: "%.1f")m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text(record.entryTime, style: .date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var durationText: String {
        let endTime = record.exitTime ?? Date()
        let duration = endTime.timeIntervalSince(record.entryTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let record = AttendanceRecord(context: controller.viewContext)
    record.id = UUID()
    record.workplaceId = UUID()
    record.entryTime = Date()
    record.isManual = false
    return NavigationStack {
        HistoryDetailView(record: record)
    }
    .environment(\.managedObjectContext, controller.viewContext)
}
