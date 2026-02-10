import SwiftUI
import MapKit
import GeoKintaiCore

struct StatusView: View {
    @EnvironmentObject private var store: AppStore
    private let isRunningUnderXCTest =
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some View {
        let viewModel = StatusViewModel(store: store)

        Form {
            Section("権限") {
                Picker("位置権限", selection: $store.permissionStatus) {
                    ForEach(LocationPermissionStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }

                Text(viewModel.shouldRunAutoRecording ? "自動記録: 有効" : "自動記録: 停止")
                Text("監視中リージョン: \(viewModel.monitoredWorkplaceCount)件")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if viewModel.permissionGuidance != .none {
                    Text("案内: \(viewModel.permissionGuidance.displayName)")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }

                if viewModel.hasPermissionWarning {
                    Label("位置権限が不足しているため自動記録は停止中です。", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if viewModel.canOpenSettings {
                    Button("設定アプリを開く") {
                        store.openAppSettings()
                    }
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
                if let openRecord = viewModel.openRecord {
                    Text("勤務中")
                    Text("入室: \(openRecord.entryTime.shortDateTime)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("未勤務")
                        .foregroundStyle(.secondary)
                }
            }

            Section("ミニマップ") {
                if isRunningUnderXCTest {
                    Text("テスト実行中はミニマップを省略します。")
                        .foregroundStyle(.secondary)
                } else if let region = viewModel.mapRegion, let workplace = viewModel.selectedWorkplace {
                    Map(initialPosition: .region(region)) {
                        Marker(workplace.name, coordinate: region.center)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("仕事場: \(workplace.name)")
                    Text("半径: \(Int(workplace.radius))m")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("仕事場を選択すると位置を表示します。")
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

                if let payload = viewModel.lastExport {
                    Text("最終出力: \(payload.format.displayName)")
                    Text("生成時刻: \(payload.generatedAt.shortDateTime)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Hash: \(payload.integrityHash)")
                        .font(.footnote)
                        .textSelection(.enabled)

                    ForEach(Array(viewModel.exportPreviewLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                if let message = store.lastErrorMessage, message.contains("出力") || message.contains("エクスポート") {
                    Button("再試行（CSV）") {
                        store.exportCSV()
                    }
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
