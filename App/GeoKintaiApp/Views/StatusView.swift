import SwiftUI
import GeoKintaiCore

struct StatusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("権限") {
                Picker("位置権限", selection: $store.permissionStatus) {
                    ForEach(LocationPermissionStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }

                Text(store.permissionDecision.shouldRunAutoRecording ? "自動記録: 有効" : "自動記録: 停止")

                if store.permissionDecision.guidance != .none {
                    Text("案内: \(store.permissionDecision.guidance.displayName)")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }

            Section("勤務操作") {
                if store.workplaces.isEmpty {
                    Text("仕事場がありません。Settings から追加してください。")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("仕事場", selection: $store.selectedWorkplaceId) {
                        ForEach(store.workplaces, id: \.id) { workplace in
                            Text(workplace.name).tag(Optional(workplace.id))
                        }
                    }

                    Button("出勤シミュレート") {
                        store.simulateCheckIn()
                    }

                    Button("退勤シミュレート") {
                        store.simulateCheckOut()
                    }
                }
            }

            Section("現在状態") {
                if let openRecord = store.attendanceRecords.first(where: { $0.exitTime == nil }) {
                    Text("勤務中")
                    Text("入室: \(openRecord.entryTime.shortDateTime)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("未勤務")
                        .foregroundStyle(.secondary)
                }
            }

            Section("エクスポート") {
                Button("CSV 出力") {
                    store.exportCSV()
                }

                Button("PDF 出力") {
                    store.exportPDF()
                }

                if let payload = store.lastExport {
                    Text("最終出力: \(payload.format.displayName)")
                    Text("Hash: \(payload.integrityHash)")
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }

            if let message = store.lastErrorMessage {
                Section("メッセージ") {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("GeoKintai")
    }
}

private extension LocationPermissionStatus {
    var displayName: String {
        switch self {
        case .always:
            return "Always"
        case .whenInUse:
            return "When In Use"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        }
    }
}

private extension PermissionGuidance {
    var displayName: String {
        switch self {
        case .none:
            return "なし"
        case .requestAlwaysAuthorization:
            return "Always 権限リクエスト"
        case .openSettings:
            return "設定アプリへ誘導"
        }
    }
}

private extension ExportFormat {
    var displayName: String {
        switch self {
        case .csv:
            return "CSV"
        case .pdf:
            return "PDF"
        }
    }
}
