import SwiftUI
import MapKit
import CoreLocation

struct WorkplaceEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let workplace: Workplace?

    @State private var name: String = ""
    @State private var radius: Double = 100.0
    @State private var monitoringEnabled: Bool = true
    @State private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var isNewWorkplace: Bool { workplace == nil }

    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Workplace Name", text: $name)
            }

            Section(header: Text("Location")) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        Marker(name.isEmpty ? "Workplace" : name, coordinate: coordinate)
                        MapCircle(center: coordinate, radius: radius)
                            .foregroundStyle(.blue.opacity(0.2))
                            .stroke(.blue, lineWidth: 2)
                    }
                    .frame(height: 250)
                    .onTapGesture { location in
                        if let coord = proxy.convert(location, from: .local) {
                            coordinate = coord
                        }
                    }
                }
                .listRowInsets(EdgeInsets())

                Button {
                    requestCurrentLocation()
                } label: {
                    Label("Use Current Location", systemImage: "location.fill")
                }
            }

            Section(header: Text("Radius")) {
                VStack(alignment: .leading) {
                    Text("\(Int(radius)) meters")
                        .font(.headline)
                    Slider(value: $radius, in: 50...500, step: 10)
                }
            }

            Section {
                Toggle("Monitoring Enabled", isOn: $monitoringEnabled)
            }
        }
        .navigationTitle(isNewWorkplace ? "Add Workplace" : "Edit Workplace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNewWorkplace {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveWorkplace()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            loadWorkplaceData()
        }
    }

    private func loadWorkplaceData() {
        if let workplace = workplace {
            name = workplace.name
            radius = workplace.radius
            monitoringEnabled = workplace.monitoringEnabled
            coordinate = CLLocationCoordinate2D(latitude: workplace.kLatitude, longitude: workplace.kLongitude)
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }

    private func requestCurrentLocation() {
        let manager = CLLocationManager()
        if let location = manager.location {
            coordinate = location.coordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }

    private func saveWorkplace() {
        let target: Workplace
        if let existing = workplace {
            target = existing
        } else {
            target = Workplace(context: viewContext)
            target.id = UUID()
            target.createdAt = Date()
        }

        target.name = name.trimmingCharacters(in: .whitespaces)
        target.kLatitude = coordinate.latitude
        target.kLongitude = coordinate.longitude
        target.radius = radius
        target.monitoringEnabled = monitoringEnabled

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    return NavigationStack {
        WorkplaceEditView(workplace: nil)
    }
    .environment(\.managedObjectContext, controller.viewContext)
}
