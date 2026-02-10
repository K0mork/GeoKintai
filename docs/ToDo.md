# TDD実装 ToDo

本チェックリストは、GeoKintai を TDD で実装する際の実行用 ToDo です。  
詳細ルールは [tdd_rules.md](tdd_rules.md) を参照してください。

## 1. 実装開始前
- [x] [specification.md](specification.md) を確認し、対象 `FR-*` を決める
- [x] [acceptance_criteria.md](acceptance_criteria.md) から対象 `AC-*` を決める
- [x] [requirements_traceability.md](requirements_traceability.md) に対象行があることを確認する
- [x] 影響タスク（`P1-*`, `P2-*`, `P3-*`）を特定する
- [x] 判定固定値を確認する（滞在 `5分` / 再確認 `2分` / 半径既定値 `100m`）

## 2. 1サイクル（Red -> Green -> Refactor）
- [x] Red: `AC-*` に対応する失敗テストを1件追加
- [x] Green: 追加テストを通す最小実装のみ追加
- [x] Refactor: 振る舞いを変えずに責務分離と命名を改善
- [x] 変更範囲テストを再実行してグリーン確認
- [x] `requirements_traceability.md` の状態を更新

## 3. 実装中の必須確認
- [x] `View` に業務ロジックを残していない
- [x] `Clock` 等で時刻依存を抽象化している（`sleep` 非依存）
- [x] append-only 制約（修正履歴）を壊していない
- [x] 位置証拠ログと整合性ハッシュの保存要件を満たしている

## 4. 日次の進行管理
- [x] その日の対象 `FR-*` / `AC-*` を宣言して着手
- [ ] サイクル単位で小さくコミットする
- [ ] 区切りで `push` してリモートへ反映する
- [ ] 未完了項目は翌日の先頭に繰り越し記録する

## 5. PR前チェック
- [x] 変更対象の Unit Test が全てグリーン
- [ ] 主要 Integration / Simulator ケースを実施
- [ ] [simulator_test_plan.md](simulator_test_plan.md) の該当 `T-*` 結果を更新
- [x] 要件・受け入れ基準・トレーサビリティの整合を確認
- [ ] ドキュメントのリンク切れがない

## 6. 完了条件
- [ ] 対象 `AC-*` がすべて満たされている
- [x] 追加/変更分が `requirements_traceability.md` に反映済み
- [x] 実装・テスト・ドキュメントが同じスコープで揃っている

## 関連ドキュメント
- [tdd_rules.md](tdd_rules.md)
- [tdd_guide.md](tdd_guide.md)
- [testing_strategy.md](testing_strategy.md)
- [simulator_test_plan.md](simulator_test_plan.md)
- [tasks/01_core_logic.md](tasks/01_core_logic.md)
- [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md)
- [tasks/03_integration.md](tasks/03_integration.md)
