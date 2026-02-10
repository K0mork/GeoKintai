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

### 2.2 実行前チェック
- [ ] 仕事場が登録済み
- [ ] `monitoringEnabled = true`
- [ ] 位置権限が `Always`
- [ ] コンソールログ確認可能

## 3. 実行手順
1. Simulator でアプリを起動する（Debug）。
2. `Debug > Simulate Location` で GPX を選択する。
3. バックグラウンド確認は `Shift + Command + H` でホームへ戻す。
4. UI状態、履歴、ログを結果表に記録する。

## 4. ケース一覧

### 4.1 基本
| ID | シナリオ | GPX | 期待値 | 対応AC |
|---|---|---|---|---|
| T-001 | 正常な出勤 | Commute_In | 勤務中へ遷移し記録作成 | AC-02 |
| T-002 | 正常な退勤 | Commute_Out | 退勤確定し `exitTime` 記録 | AC-04 |
| T-003 | 通過誤検知防止 | Pass_By | 出勤記録なし | AC-03 |
| T-004 | アプリキル後挙動 | Commute_In | 参考確認（実機推奨） | AC-02 |

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

## 7. 注意事項
- シミュレータ結果は実機と差分があり得る。
- 重要ケース（T-001, T-002, T-006, T-012）は実機再確認を推奨する。
- 連続実行時は状態リセットを行う。
