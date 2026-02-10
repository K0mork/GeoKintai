# 要件トレーサビリティマトリクス

本表は `FR/NFR`、`AC/NFC`、テスト、タスクの対応を一元管理する。  
変更時は本表を必ず同期更新する。

| Req ID | 要件概要 | 受け入れ基準 | Unit Test（例） | Simulator Test | 実装タスク | 状態 |
|---|---|---|---|---|---|---|
| FR-01 | 仕事場 CRUD | AC-01 | `WorkplaceRepositoryTests` | T-011 | P1-010, P2-030 | Planned |
| FR-02 | 出勤確定（滞在判定） | AC-02 | `StayVerifierTests` | T-001, T-008 | P1-030, P3-020 | Planned |
| FR-03 | 通過誤検知防止 | AC-03 | `StayVerifierTests` | T-003, T-005, T-009 | P1-030, P3-020 | Planned |
| FR-04 | 退勤確定（再確認） | AC-04 | `ExitVerifierTests` | T-002, T-006 | P1-040, P3-020 | Planned |
| FR-05 | 勤務中一意性 | AC-05 | `AttendanceRepositoryTests` | T-001, T-002 | P1-020 | Planned |
| FR-06 | 手動修正監査 | AC-06 | `AttendanceCorrectionRepositoryTests` | T-011 | P1-050, P2-020 | Planned |
| FR-07 | 複数仕事場独立性 | AC-07 | `RegionRoutingTests` | T-007, T-011 | P1-010, P3-020 | Planned |
| FR-08 | エクスポート完全性 | AC-08 | `ExportServiceTests` | T-010 | P2-040, P3-030 | Planned |
| FR-09 | 権限不足時安全動作 | AC-09 | `PermissionUseCaseTests` | T-012, T-013 | P2-050, P3-020 | Planned |
| FR-10 | 改ざん検知 | AC-10 | `IntegrityHashTests` | T-010 | P1-060, P3-030 | Planned |
| NFR-01 | 時刻整合性 | NFC-01 | `TimeZoneConversionTests` | T-010 | P1-070 | Planned |
| NFR-02 | 再現可能性 | NFC-02 | 判定ロジック一式 | T-001〜T-010 | P1-030, P1-040 | Planned |
| NFR-03 | 監査可能性 | NFC-03 | `LocationProofRepositoryTests` | T-001, T-002 | P1-050 | Planned |
| NFR-04 | 追記型監査ログ | NFC-04 | `AuditLogAppendOnlyTests` | T-011 | P1-050, P1-060 | Planned |
| NFR-05 | 可観測性 | NFC-05 | `LoggingServiceTests` | T-001, T-012 | P3-040 | Planned |
| NFR-06 | 異常系安全性 | NFC-06 | `FailureHandlingTests` | T-013 | P3-050 | Planned |

## 運用ルール
- 要件追加時は `Req ID` を採番して1行追加する。
- テストケースIDやタスクIDを変えた場合は、同一コミットで本表を更新する。
- `状態` は `Planned / In Progress / Done / Blocked` を使用する。

## 参照
- [specification.md](specification.md)
- [acceptance_criteria.md](acceptance_criteria.md)
- [simulator_test_plan.md](simulator_test_plan.md)
- [tasks/01_core_logic.md](tasks/01_core_logic.md)
- [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md)
- [tasks/03_integration.md](tasks/03_integration.md)
