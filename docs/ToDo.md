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
- [x] サイクル単位で小さくコミットする
- [x] 区切りで `push` してリモートへ反映する
- [x] 未完了項目は翌日の先頭に繰り越し記録する

## 5. PR前チェック
- [x] 変更対象の Unit Test が全てグリーン
- [x] 主要 Integration / Simulator ケースを実施
- [x] [simulator_test_plan.md](simulator_test_plan.md) の該当 `T-*` 結果を更新
- [x] 要件・受け入れ基準・トレーサビリティの整合を確認
- [x] ドキュメントのリンク切れがない

## 6. 完了条件
- [x] 対象 `AC-*` がすべて満たされている
- [x] 追加/変更分が `requirements_traceability.md` に反映済み
- [x] 実装・テスト・ドキュメントが同じスコープで揃っている

## 7. 最新更新（2026-02-10）
- [x] `FR-01 / AC-01` の入力バリデーションを強化（緯度/経度の範囲チェック）
- [x] 座標入力の前後空白を許容する挙動を追加
- [x] `AppStoreIntegrationTests` に FR-01 関連の回帰テスト3件を追加
- [x] 不足していた異常系テストを補強（削除時監視除外、更新失敗、退勤失敗、手動修正失敗、エクスポート失敗）
- [x] `CoreLocation` 連携を実装し、バックグラウンド位置イベント（入域/退域/初期 inside 判定）から自動記録フローへ接続
- [x] 起動時に監視リージョンの現在状態を取得し、職場内起動時の滞在判定開始を実装
- [x] `AppStoreIntegrationTests` にバックグラウンド系回帰テストを追加（滞在5分確定、早期離脱、位置取得失敗）
- [x] CI/ローカル実行時の主要警告を整理し、対策を実装（destination重複、AppIntents metadata、Map起因の起動警告）
- [x] `./scripts/run_all_checks.sh` で全チェックのグリーンを確認
- [x] ドキュメント（仕様/受け入れ基準/トレーサビリティ/テスト運用）を同期更新

## 8. 警告潰しチェックリスト（2026-02-10）
- [x] `xcodebuild -destination` を一意指定に変更し `Using the first of multiple matching destinations` を解消
- [x] `AppIntents` 依存アンカーファイルを追加し `Metadata extraction skipped. No AppIntents.framework dependency found.` を解消
- [x] XCTest 実行時はミニマップ描画を省略し `[ResourceManifest] default.csv` / `CAMetalLayer ... setDrawableSize` を解消
- [x] シミュレータ由来の `[PPT] Error creating the CFMessagePort...` は `run_all_checks.sh` で該当1行のみフィルタ

## 関連ドキュメント
- [tdd_rules.md](tdd_rules.md)
- [tdd_guide.md](tdd_guide.md)
- [testing_strategy.md](testing_strategy.md)
- [simulator_test_plan.md](simulator_test_plan.md)
- [tasks/01_core_logic.md](tasks/01_core_logic.md)
- [tasks/02_ui_implementation.md](tasks/02_ui_implementation.md)
- [tasks/03_integration.md](tasks/03_integration.md)
