import SwiftUI
import GeoKintaiCore

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            if groupedAttendances.isEmpty {
                Section("勤務履歴") {
                    Text("履歴がありません。")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedAttendances) { group in
                    Section("勤務履歴 \(group.title)") {
                        ForEach(group.records, id: \.id) { record in
                            NavigationLink {
                                AttendanceRecordDetailView(recordId: record.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.workplaceName(for: record.workplaceId))
                                        .font(.headline)
                                    Text("入室: \(record.entryTime.shortDateTime)")
                                    Text("退室: \(record.exitTime?.shortDateTime ?? "-")")
                                        .foregroundStyle(record.exitTime == nil ? .orange : .primary)
                                }
                            }
                        }
                    }
                }
            }

            Section("修正履歴タイムライン") {
                if store.corrections.isEmpty {
                    Text("修正履歴はありません。")
                        .foregroundStyle(.secondary)
                } else {
                    if !store.corruptedCorrectionIds.isEmpty {
                        Label(
                            "整合性不一致: \(store.corruptedCorrectionIds.count)件",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.red)
                    }

                    ForEach(store.corrections, id: \.id) { correction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(correction.correctedAt.shortDateTime)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("\(correction.before.entryTime.shortDateTime) -> \(correction.after.entryTime.shortDateTime)")
                            Text(correction.reason)
                                .font(.callout)
                            Text("Hash: \(correction.integrityHash)")
                                .font(.caption2)
                                .textSelection(.enabled)
                            if store.corruptedCorrectionIds.contains(correction.id) {
                                Text("この修正レコードは整合性不一致です。")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
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
    }

    private var groupedAttendances: [AttendanceDayGroup] {
        let calendar = Calendar(identifier: .gregorian)
        let grouped = Dictionary(grouping: store.attendanceRecords) { record in
            calendar.startOfDay(for: record.entryTime)
        }

        return grouped.keys
            .sorted(by: >)
            .map { day in
                AttendanceDayGroup(
                    day: day,
                    records: grouped[day, default: []].sorted(by: { $0.entryTime > $1.entryTime })
                )
            }
    }
}

private struct AttendanceRecordDetailView: View {
    @EnvironmentObject private var store: AppStore
    let recordId: UUID

    @State private var reason = ""
    @State private var correctedEntryTime = Date()
    @State private var correctedExitTime = Date()
    @State private var shouldEditExitTime = false

    private var record: AttendanceRecord? {
        store.attendanceRecords.first(where: { $0.id == recordId })
    }

    private var relatedProofs: [LocationProof] {
        store.proofs.filter { $0.attendanceRecordId == recordId }
    }

    private var relatedCorrections: [AttendanceCorrection] {
        store.corrections.filter { $0.attendanceRecordId == recordId }
    }

    var body: some View {
        Form {
            if let record {
                Section("基本情報") {
                    Text("仕事場: \(store.workplaceName(for: record.workplaceId))")
                    Text("入室: \(record.entryTime.shortDateTime)")
                    Text("退室: \(record.exitTime?.shortDateTime ?? "-")")
                }

                Section("位置証拠") {
                    if relatedProofs.isEmpty {
                        Text("位置証拠はありません。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(relatedProofs, id: \.id) { proof in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(proof.reason.rawValue) @ \(proof.timestamp.shortDateTime)")
                                Text("lat: \(proof.latitude), lon: \(proof.longitude), acc: \(proof.horizontalAccuracy)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("手動修正（理由必須）") {
                    TextField("修正理由", text: $reason)
                    DatePicker("修正後の出勤時刻", selection: $correctedEntryTime)

                    if record.exitTime != nil {
                        Toggle("退勤時刻も修正する", isOn: $shouldEditExitTime)
                        if shouldEditExitTime {
                            DatePicker("修正後の退勤時刻", selection: $correctedExitTime)
                        }
                    }

                    Button("修正を保存") {
                        let correctedExit: Date?
                        if record.exitTime == nil {
                            correctedExit = nil
                        } else if shouldEditExitTime {
                            correctedExit = correctedExitTime
                        } else {
                            correctedExit = record.exitTime
                        }

                        store.addManualCorrection(
                            recordId: record.id,
                            reason: reason,
                            correctedEntryTime: correctedEntryTime,
                            correctedExitTime: correctedExit
                        )

                        if store.lastErrorMessage == nil {
                            reason = ""
                        }
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("対象レコードの修正履歴") {
                    if relatedCorrections.isEmpty {
                        Text("修正履歴はありません。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(relatedCorrections, id: \.id) { correction in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(correction.correctedAt.shortDateTime)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("入室: \(correction.before.entryTime.shortDateTime) -> \(correction.after.entryTime.shortDateTime)")
                                Text("理由: \(correction.reason)")
                            }
                        }
                    }
                }
            } else {
                Text("対象レコードが見つかりません。")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("履歴詳細")
        .onAppear {
            if let record {
                correctedEntryTime = record.entryTime
                if let exitTime = record.exitTime {
                    correctedExitTime = exitTime
                }
            }
        }
    }
}

private struct AttendanceDayGroup: Identifiable {
    let day: Date
    let records: [AttendanceRecord]

    var id: Date { day }
    var title: String { day.dayOnlyText }
}

private extension Date {
    static let historyDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var dayOnlyText: String {
        Date.historyDayFormatter.string(from: self)
    }
}
