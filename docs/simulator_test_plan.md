# シミュレータテスト計画

この文書は、Xcode シミュレータで実施するテストケース（`T-*`）の正本である。  
テスト運用は [testing_strategy.md](testing_strategy.md) を参照する。

## 1. 対象範囲
- 対象: 入域/滞在判定/退域再確認/権限変化/複数仕事場
- 非対象: 実機依存の完全バックグラウンド再現（必要時は実機試験へ移管）

## 2. 事前準備

### 2.1 GPX 一覧（`SimulatedLocations/`）
| ファイル名 | 用途 | 主な検証対象 |
|---|---|---|
| Workplace.gpx | 仕事場中心確認 | FR-01 |
| Commute_In.gpx | 出勤検知 | FR-02 |
| Commute_Out.gpx | 退勤検知 | FR-04 |
| Pass_By.gpx | 通過誤検知防止 | FR-03 |
| Short_Stay.gpx | 短時間滞在 | FR-03 |
| GPS_Drift.gpx | GPS 揺らぎ | FR-04 |
| Multiple_Visits.gpx | 複数回出入り | FR-07 |
| Boundary_Edge.gpx | 境界条件 | FR-02 |
| Fast_Transit.gpx | 高速通過 | FR-03 |
| Late_Night.gpx | 深夜帯 | NFR-01 |

補足: GPXファイルはリポジトリ直下の `SimulatedLocations/` に配置する。

### 2.2 実行前チェック
- [ ] 仕事場が登録済み
- [ ] `monitoringEnabled = true`
- [ ] 位置権限が `Always`
- [ ] コンソールログ確認可能

## 3. 実行手順
1. Simulator でアプリを起動する（Debug）。
2. `Debug > Simulate Location` で GPX を選択する。
3. CLI 実行する場合は `scripts/run_simulator_gpx.sh <simulator_udid> <gpx_file>` を利用する。
4. 一括実行する場合は `scripts/run_simulator_suite.sh [simulator_udid] [log_file]` を利用する。
5. バックグラウンド確認は `Shift + Command + H` でホームへ戻す。
6. UI状態、履歴、ログを結果表に記録する。

## 4. ケース一覧

### 4.1 基本
| ID | シナリオ | GPX | 期待値 | 対応AC |
|---|---|---|---|---|
| T-001 | 正常な出勤 | Commute_In | 勤務中へ遷移し記録作成 | AC-02 |
| T-002 | 正常な退勤 | Commute_Out | 退勤確定し `exitTime` 記録 | AC-04 |
| T-003 | 通過誤検知防止 | Pass_By | 出勤記録なし | AC-03 |
| T-004 | アプリキル後挙動 | Commute_In | 実機で確認（手順は `real_device_test_plan.md`） | AC-02 |

### 4.2 エッジケース
| ID | シナリオ | GPX | 期待値 | 対応AC |
|---|---|---|---|---|
| T-005 | 短時間滞在 | Short_Stay | 出勤記録なし | AC-03 |
| T-006 | GPS 揺らぎ | GPS_Drift | 誤退勤しない | AC-04 |
| T-007 | 複数回出入り | Multiple_Visits | 複数レコードを分離記録 | AC-07 |
| T-008 | 境界線上滞在 | Boundary_Edge | 出勤判定が安定 | AC-02 |
| T-009 | 高速通過 | Fast_Transit | 出勤記録なし | AC-03 |
| T-010 | 深夜出勤 | Late_Night | 時刻整合性維持 | NFC-01 |

### 4.3 複合
| ID | シナリオ | 手順 | 期待値 | 対応AC |
|---|---|---|---|---|
| T-011 | 複数仕事場 | 各仕事場で Commute_In 実行 | 仕事場ごとに独立記録 | AC-07 |
| T-012 | 権限変更 | `Always` -> `When In Use` | 自動記録停止 + 導線表示 | AC-09 |
| T-013 | 機内モード | 機内モード ON で再生 | 検知失敗を安全処理 | AC-09 |

## 5. 実行後チェック
- [ ] 期待ステータスに遷移した
- [ ] History に期待件数が記録された
- [ ] LocationProof が保存された
- [ ] 重大エラーが出ていない

## 6. 記録テンプレート
| ケースID | 実施日 | 実施者 | 結果 | 逸脱内容 | 再現手順 |
|---|---|---|---|---|---|
| T-xxx | YYYY-MM-DD | Name | Pass/Fail | なし/詳細 | 必要時のみ |

### 6.1 実施結果（2026-02-10）
| ケースID | 実施日 | 実施者 | 結果 | 逸脱内容 | 再現手順 |
|---|---|---|---|---|---|
| T-001 | 2026-02-10 | Codex | Pass | GPX再生 + `AttendanceFlowIntegrationTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Commute_In.gpx` |
| T-002 | 2026-02-10 | Codex | Pass | GPX再生 + `AttendanceFlowIntegrationTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Commute_Out.gpx` |
| T-003 | 2026-02-10 | Codex | Pass | GPX再生 + `AttendanceFlowIntegrationTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Pass_By.gpx` |
| T-004 | 2026-02-10 | Codex | Skip | アプリキル後挙動はシミュレータ制約が大きく、実機推奨 | 実機で再検証予定 |
| T-005 | 2026-02-10 | Codex | Pass | GPX再生 + `AttendanceFlowIntegrationTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Short_Stay.gpx` |
| T-006 | 2026-02-10 | Codex | Pass | GPX再生 + `ExitVerifierTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/GPS_Drift.gpx` |
| T-007 | 2026-02-10 | Codex | Pass | GPX再生 + `AttendanceFlowIntegrationTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Multiple_Visits.gpx` |
| T-008 | 2026-02-10 | Codex | Pass | GPX再生 + `StayVerifierTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Boundary_Edge.gpx` |
| T-009 | 2026-02-10 | Codex | Pass | GPX再生 + `StayVerifierTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Fast_Transit.gpx` |
| T-010 | 2026-02-10 | Codex | Pass | GPX再生 + `TimeZoneConversionTests` で確認（UI目視は未実施） | `scripts/run_simulator_gpx.sh <udid> SimulatedLocations/Late_Night.gpx` |
| T-011 | 2026-02-10 | Codex | Pass | `RegionRoutingTests` と統合テストで分離確認（UI目視は未実施） | `swift test --filter test_regionRouter_whenMultipleBindings_routesToCorrectWorkplace` |
| T-012 | 2026-02-10 | Codex | Pass | `AppStoreIntegrationTests` で権限低下時の安全動作を確認 | `xcodebuild ... -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenPermissionDowngraded_stopsMonitoringAndPreventsAutoRecord test` |
| T-013 | 2026-02-10 | Codex | Pass | `FailureHandlingTests` で異常時保護動作を確認（機内モードそのものは未操作） | `swift test --filter test_failureHandling_whenLocationUnavailable_preservesDataAndRetries` |

補足: 実行ログは `docs/simulator_run_log_2026-02-10.txt` を参照。

## 7. 注意事項
- シミュレータ結果は実機と差分があり得る。
- 重要ケース（T-001, T-002, T-006, T-012）は実機再確認を推奨する。
- 連続実行時は状態リセットを行う。
