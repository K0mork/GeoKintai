import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            Section("勤務履歴") {
                if store.attendanceRecords.isEmpty {
                    Text("履歴がありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.attendanceRecords, id: \.id) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workplace: \(record.workplaceId.uuidString)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("入室: \(record.entryTime.shortDateTime)")
                            Text("退室: \(record.exitTime?.shortDateTime ?? "-")")
                        }
                    }
                }
            }

            Section("修正履歴") {
                if store.corrections.isEmpty {
                    Text("修正履歴はありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.corrections, id: \.id) { correction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(correction.reason)
                            Text("日時: \(correction.correctedAt.shortDateTime)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("Hash: \(correction.integrityHash)")
                                .font(.caption2)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section("位置証拠") {
                if store.proofs.isEmpty {
                    Text("位置証拠はありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.proofs, id: \.id) { proof in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(proof.reason.rawValue) @ \(proof.timestamp.shortDateTime)")
                            Text("lat: \(proof.latitude), lon: \(proof.longitude), acc: \(proof.horizontalAccuracy)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("イベントログ") {
                let logItems = Array(store.logs.enumerated()).suffix(20)
                if logItems.isEmpty {
                    Text("ログはまだありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(logItems), id: \.offset) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.element.timestamp.shortDateTime)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(item.element.message)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            Button("修正サンプル追加") {
                store.addSampleCorrection()
            }
        }
    }
}
