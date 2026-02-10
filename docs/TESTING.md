# テスト戦略

GeoKintaiのテストは、要件追跡とTDDを前提に次の順序で実施します。

## 1. 参照ドキュメント
- 実行規約: [Development Rules (TDD)](development_rules.md)
- 詳細ガイド: [TDD実行ガイド](tdd_guide.md)
- 受け入れ基準: [acceptance_criteria.md](acceptance_criteria.md)
- 要件対応表: [requirements_traceability.md](requirements_traceability.md)
- シミュレータ手順: [test_plan.md](test_plan.md)

## 2. テストレベル

### 2.1 Unit Test（最優先）
- 対象: ViewModels, Repositories, UseCases, Services
- ツール: XCTest, Dependency Injection, Test Double
- 目的: 判定ロジックの正しさを高速に検証する
- 補足: 受け入れ基準 `AC-*` は必ず最低1つのユニットテストに紐づける

### 2.2 Integration / Simulator Test
- 対象: Core Data連携、Location Service連携、バックグラウンド遷移
- ツール: Xcode Simulator, GPX
- 目的: OS連携を含むシナリオ妥当性を確認する

### 2.3 UI Test（段階導入）
- 対象: クリティカルな操作導線（設定、履歴確認、権限導線）
- ツール: XCUITest
- 方針: Phase 1では最小構成、機能安定後に拡張

## 3. 品質ゲート
- 新機能は `Red -> Green -> Refactor` のログが追えること
- 変更箇所の対応 `Req ID` を `requirements_traceability.md` に反映すること
- 既存テストがグリーンであること
