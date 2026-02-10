import SwiftUI
import GeoKintaiCore

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var newName = ""
    @State private var newLatitude = ""
    @State private var newLongitude = ""
    @State private var newRadius = ""
    @State private var editingWorkplace: Workplace?

    var body: some View {
        Form {
            Section("仕事場追加") {
                TextField("名称", text: $newName)
                TextField("緯度", text: $newLatitude)
                    .keyboardType(.decimalPad)
                TextField("経度", text: $newLongitude)
                    .keyboardType(.decimalPad)
                TextField("半径(m, 省略時100)", text: $newRadius)
                    .keyboardType(.decimalPad)

                Button("追加") {
                    store.addWorkplace(
                        name: newName,
                        latitudeText: newLatitude,
                        longitudeText: newLongitude,
                        radiusText: newRadius
                    )
                    if store.lastErrorMessage == nil {
                        newName = ""
                        newLatitude = ""
                        newLongitude = ""
                        newRadius = ""
                    }
                }
            }

            Section("仕事場一覧") {
                if store.workplaces.isEmpty {
                    Text("登録済み仕事場はありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.workplaces, id: \.id) { workplace in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workplace.name).font(.headline)
                            Text("lat: \(workplace.latitude), lon: \(workplace.longitude), r: \(Int(workplace.radius))m")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Toggle(
                                "監視有効",
                                isOn: Binding(
                                    get: { workplace.monitoringEnabled },
                                    set: { store.setMonitoring(id: workplace.id, enabled: $0) }
                                )
                            )

                            HStack {
                                Button("編集") {
                                    editingWorkplace = workplace
                                }

                                Spacer()

                                Button("削除", role: .destructive) {
                                    store.deleteWorkplace(id: workplace.id)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if let message = store.lastErrorMessage {
                Section("メッセージ") {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(
            isPresented: Binding(
                get: { editingWorkplace != nil },
                set: { isPresented in
                    if !isPresented {
                        editingWorkplace = nil
                    }
                }
            )
        ) {
            if let editingWorkplace {
                WorkplaceEditorSheet(workplace: editingWorkplace)
            }
        }
    }
}

private struct WorkplaceEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let workplace: Workplace

    @State private var name = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radius = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("仕事場編集") {
                    TextField("名称", text: $name)
                    TextField("緯度", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("経度", text: $longitude)
                        .keyboardType(.decimalPad)
                    TextField("半径(m)", text: $radius)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("仕事場編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.updateWorkplace(
                            id: workplace.id,
                            name: name,
                            latitudeText: latitude,
                            longitudeText: longitude,
                            radiusText: radius
                        )
                        if store.lastErrorMessage == nil {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            name = workplace.name
            latitude = String(workplace.latitude)
            longitude = String(workplace.longitude)
            radius = String(workplace.radius)
        }
    }
}
