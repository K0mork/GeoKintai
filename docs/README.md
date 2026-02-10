# GeoKintai ドキュメントハブ

このディレクトリは、GeoKintai を TDD で開発するための設計・検証ドキュメントを管理します。  
重複を避けるため、各文書の責務を固定しています。

## 1. ドキュメント構成

| 文書 | 役割 | 参照タイミング |
|---|---|---|
| [specification.md](specification.md) | 機能要件・非機能要件・ドメイン制約の正本 | 要件定義、仕様変更時 |
| [acceptance_criteria.md](acceptance_criteria.md) | 実装の合格条件（Given/When/Then） | 実装前、レビュー前 |
| [logic_flow.md](logic_flow.md) | 位置イベント処理の時系列フロー | 設計・障害調査時 |
| [tdd_rules.md](tdd_rules.md) | TDD の不変ルール（上位規約） | 常時 |
| [tdd_guide.md](tdd_guide.md) | 1サイクルの進め方（実務手順） | 実装中 |
| [testing_strategy.md](testing_strategy.md) | テストレベル戦略と実行運用 | 実装中、PR前 |
| [simulator_test_plan.md](simulator_test_plan.md) | シミュレータ検証シナリオ（T-*） | 統合確認時 |
| [real_device_test_plan.md](real_device_test_plan.md) | 実機依存ケース（T-004）の検証手順 | 実機確認時 |
| [test_plan.md](test_plan.md) | 旧名称互換エントリ（シミュレータ/実機計画への導線） | 旧導線参照時 |
| [TESTING.md](TESTING.md) | 旧名称互換エントリ（testing_strategy への導線） | 旧導線参照時 |
| [requirements_traceability.md](requirements_traceability.md) | FR/AC/Test/Task の対応表 | 変更時に都度更新 |
| [tasks/01_core_logic.md](tasks/01_core_logic.md) | Phase 1: Core Logic 実装タスク | 開発計画時 |
| [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md) | Phase 2: UI 実装タスク | 開発計画時 |
| [tasks/03_integration.md](tasks/03_integration.md) | Phase 3: 統合・検証タスク | リリース準備時 |

## 2. 推奨読了順

### 実装開始前
1. [specification.md](specification.md)
2. [acceptance_criteria.md](acceptance_criteria.md)
3. [logic_flow.md](logic_flow.md)
4. [tdd_rules.md](tdd_rules.md)
5. [requirements_traceability.md](requirements_traceability.md)

### 実装中
1. [tdd_guide.md](tdd_guide.md)
2. [testing_strategy.md](testing_strategy.md)
3. [tasks/01_core_logic.md](tasks/01_core_logic.md)
4. [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md)
5. [tasks/03_integration.md](tasks/03_integration.md)

### 統合確認時
1. [testing_strategy.md](testing_strategy.md)
2. [simulator_test_plan.md](simulator_test_plan.md)
3. [real_device_test_plan.md](real_device_test_plan.md)
4. [requirements_traceability.md](requirements_traceability.md)

## 3. 同期更新ルール
- 仕様変更時は `specification.md`、`acceptance_criteria.md`、`requirements_traceability.md` を同時更新する。
- TDD 運用変更時は `tdd_rules.md` と `tdd_guide.md` を同時確認する。
- テスト実行運用の変更時は `testing_strategy.md` を正本として更新する。
- シミュレータケース（`T-*`）を変更したら `simulator_test_plan.md` と `requirements_traceability.md` を同時更新する。
- 実装タスクを変更したら該当する `tasks/*.md` と `requirements_traceability.md` を同時更新する。

## 4. 命名規約
- 要件ID: `FR-*`, `NFR-*`
- 受け入れ基準ID: `AC-*`, `NFC-*`
- シミュレータテストID: `T-*`
- タスクID: `P<Phase>-*`
