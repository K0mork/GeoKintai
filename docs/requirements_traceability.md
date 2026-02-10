# 要件トレーサビリティマトリクス

仕様・受け入れ基準・テスト・タスクを一貫して追跡するための対応表です。  
`AC-*` は [受け入れ基準](acceptance_criteria.md) を参照します。

| Req ID | 要件 | 受け入れ基準 | Unit Test（予定） | Integration / Simulator Test | タスク |
|---|---|---|---|---|---|
| FR-01 | 仕事場CRUD | AC-01 | `WorkplaceRepositoryTests` | 設定画面で追加/削除確認 | `tasks/01_core_logic.md`, `tasks/02_ui_implementation.md` |
| FR-02 | 出勤確定（滞在判定） | AC-02 | `StayVerifierTests`, `AttendanceRepositoryTests` | T-001 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |
| FR-03 | 通過時誤検知防止 | AC-03 | `StayVerifierTests` | T-003, T-009 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |
| FR-04 | 退勤確定（再確認） | AC-04 | `ExitVerifierTests`, `AttendanceRepositoryTests` | T-002, T-006 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |
| FR-05 | 勤務中レコード重複防止 | AC-05 | `AttendanceRepositoryTests` | 複合シナリオで再入場検証 | `tasks/01_core_logic.md` |
| FR-06 | 手動修正監査性（追記型） | AC-06 | `AttendanceCorrectionRepositoryTests` | 履歴詳細で修正タイムライン確認 | `tasks/01_core_logic.md`, `tasks/02_ui_implementation.md` |
| FR-07 | 複数仕事場独立性 | AC-07 | `RegionRoutingTests` | T-011 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |
| FR-08 | エクスポート完全性 | AC-08 | `ExportServiceTests` | サンプル出力目視検証 | `tasks/02_ui_implementation.md`, `tasks/03_integration.md` |
| FR-09 | 権限不足時の安全動作 | AC-09 | `PermissionUseCaseTests` | T-012 | `tasks/02_ui_implementation.md`, `tasks/03_integration.md` |
| FR-10 | 改ざん検知 | AC-10 | `IntegrityHashTests` | 出力ファイル再検証 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |
| NFR-01 | 時刻整合性 | NFC-01 | `TimeZoneConversionTests` | 深夜シナリオ T-010 | `tasks/01_core_logic.md` |
| NFR-02 | 再現可能性 | NFC-02 | 判定ロジック一式 | T-001〜T-010 | `tasks/03_integration.md` |
| NFR-03 | 監査可能性 | NFC-03 | `LocationProofRepositoryTests` | 履歴詳細で証拠追跡確認 | `tasks/01_core_logic.md`, `tasks/02_ui_implementation.md` |
| NFR-04 | 追記型監査ログ | NFC-04 | `AuditLogAppendOnlyTests` | 監査ログの更新/削除禁止検証 | `tasks/01_core_logic.md`, `tasks/03_integration.md` |

## 運用ルール
- 新しい要件を追加したら、`Req ID` を採番して本表へ追記する。
- テスト名やタスク名を変更したら、本表のリンク先も同時に更新する。
- 未対応タスクが出た場合は、実装着手前に `tasks/` へ明示的に分解する。
