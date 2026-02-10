# GeoKintai ドキュメントガイド

このプロジェクトは、実装前にドキュメントで仕様とテスト方針を固定する運用を採用します。

## 実装前の推奨読了順
1. [仕様書](specification.md)
2. [受け入れ基準](acceptance_criteria.md)
3. [ロジックフロー](logic_flow.md)
4. [TDD実行ガイド](tdd_guide.md)
5. [テスト戦略](TESTING.md)
6. [シミュレータテスト計画](test_plan.md)
7. [要件トレーサビリティ](requirements_traceability.md)
8. [開発タスク](tasks/01_core_logic.md), [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md), [tasks/03_integration.md](tasks/03_integration.md)

## 更新ルール
- 仕様変更時は、最低でも `specification.md` / `acceptance_criteria.md` / `requirements_traceability.md` を同時更新する。
- テスト方針変更時は、`tdd_guide.md` と `TESTING.md` を同時更新する。
- タスク粒度変更時は、`tasks/` 配下と `requirements_traceability.md` の対応を更新する。

