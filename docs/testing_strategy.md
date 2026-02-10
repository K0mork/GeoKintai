# テスト戦略と実行運用

この文書は、GeoKintai のテストレベル戦略と実行タイミングを定義する。  
シナリオ正本は [simulator_test_plan.md](simulator_test_plan.md) とする。

## 1. テストレベル

### 1.1 Unit Test（最優先）
- 対象: ViewModels / UseCases / Repositories / Services
- 目的: 判定ロジックの正しさと回帰防止
- 必須: 各 `AC-*` に最低1つ対応テストを持つ

### 1.2 Integration Test
- 対象: Core Data/SwiftData 連携、Location 連携、権限分岐
- 目的: 層間接続の整合性確認

### 1.3 Simulator Test
- 対象: 入域/滞在/退域のイベント連鎖
- 目的: iOS イベント駆動の実運用に近い確認
- ケース管理: `T-*` は [simulator_test_plan.md](simulator_test_plan.md) を正本とする

### 1.4 UI Test
- 対象: 設定、履歴、権限導線、エクスポート導線
- 方針: クリティカルフローを優先して段階導入

## 2. 実行タイミング
- 実装中: 変更対象ユニットテストを都度実行
- PR 作成前: 影響範囲のユニット + 主要 Integration を実行
- マイルストーン前: 主要 `T-*` ケースを再実行

## 3. 実行コマンド例

```bash
# 推奨: 全体チェック（Swift Package + iOS App Test）
./scripts/run_all_checks.sh

# UDID を固定して実行したい場合
./scripts/run_all_checks.sh <simulator_udid>

# ドキュメントリンクのみ検証
./scripts/check_doc_links.sh

# シミュレータ検証（GPX + 主要T-*根拠テスト）
./scripts/run_simulator_suite.sh <simulator_udid>

# UDID 自動検出で実行
./scripts/run_simulator_suite.sh

# 実機ログ雛形を作成（T-004 用）
./scripts/new_real_device_log.sh <tester> <device> <os_version>

# 個別実行（必要時）
swift test

xcodebuild test \
  -project GeoKintai.xcodeproj \
  -scheme GeoKintaiApp \
  -destination "platform=iOS Simulator,id=<simulator_udid>,arch=arm64" \
  -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenPermissionDowngraded_stopsMonitoringAndPreventsAutoRecord

xcodebuild test \
  -project GeoKintai.xcodeproj \
  -scheme GeoKintaiApp \
  -destination "platform=iOS Simulator,id=<simulator_udid>,arch=arm64" \
  -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenAddWorkplaceLatitudeOutOfRange_rejectsSave \
  -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenAddWorkplaceLongitudeOutOfRange_rejectsSave \
  -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenAddWorkplaceCoordinateHasWhitespace_savesSuccessfully
```

## 4. 失敗時トリアージ
- 追加した Red が想定どおり失敗しているかを最初に確認する。
- 既存テスト失敗は回帰として最優先で修正する。
- 不安定テストは `sleep` と実時間依存を排除する。
- 要件差分が原因なら実装前に `acceptance_criteria.md` を更新する。
- `xcodebuild test` 実行時に `[PPT] Error creating the CFMessagePort...` が出る場合がある。これはシミュレータ実行時の既知ノイズのため、`run_all_checks.sh` では該当1行のみフィルタして判定ノイズを除去している。

## 5. 品質ゲート
- `Red -> Green -> Refactor` の履歴を追跡可能である。
- `requirements_traceability.md` の対応が最新である。
- マージ前に関連テストがすべてグリーンである。

## 6. 関連文書
- [tdd_rules.md](tdd_rules.md)
- [tdd_guide.md](tdd_guide.md)
- [acceptance_criteria.md](acceptance_criteria.md)
- [requirements_traceability.md](requirements_traceability.md)
- [simulator_test_plan.md](simulator_test_plan.md)
