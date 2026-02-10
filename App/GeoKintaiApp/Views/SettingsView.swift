import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var newName = ""
    @State private var newLatitude = ""
    @State private var newLongitude = ""
    @State private var newRadius = ""

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

                            Button("削除", role: .destructive) {
                                store.deleteWorkplace(id: workplace.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
