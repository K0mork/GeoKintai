# TDD実行ガイド

実装前に、テストの作法と合格基準を固定するためのガイドです。  
原則は [Development Rules](development_rules.md) を上位規約として継承します。

## 1. テストレイヤー方針
- Unit Test: 判定ロジックの正しさを検証（最優先）
- Integration Test: Core Data とサービス接続の整合性を検証
- Simulator Test: iOS連携（リージョン、バックグラウンド、GPX）を検証
- UI Test: クリティカル導線のみを最小限で検証

## 2. 1サイクルの定義（Red-Green-Refactor）
1. Red: 受け入れ基準（`AC-*`）に紐づく失敗テストを1つ追加する
2. Green: 追加したテストだけを満たす最小実装を行う
3. Refactor: 命名・重複・責務分離を改善し、全テストを再実行する

## 3. テスト命名規約
- 形式: `test_<対象>_<条件>_<期待結果>()`
- 例: `test_stayVerifier_whenInsideFor5Minutes_returnsConfirmed()`
- 1テスト1期待結果を原則とする（複数期待は避ける）

## 4. テストダブル方針
- `CLLocationManager`, `Date`, `Timer`, `BackgroundTask` は直接使わず抽象化して注入する
- モックは「振る舞いの最小再現」に限定し、実装詳細の検証は避ける
- `sleep` 依存のテストは禁止し、仮想時刻で制御する

## 5. 先に固定するインターフェース
- `Clock`: 現在時刻取得
- `LocationProvider`: 位置イベント通知
- `RegionMonitor`: 監視開始/停止
- `AttendanceStore`: 出退勤の永続化操作
- `ProofStore`: 位置証拠ログの永続化操作

## 6. Definition of Done（機能スライス単位）
- `AC-*` に対応するユニットテストが追加され、失敗から成功へ遷移している
- 既存テストを壊していない
- テスト名が振る舞いを説明している
- 必要最小限のリファクタを実施し、責務分離が悪化していない
- 対応関係を `requirements_traceability.md` に反映している
- 監査ログ項目（修正履歴、整合性ハッシュ）の検証テストを含む

## 7. 実装開始前チェック
- [ ] 滞在判定時間は `5分` で固定されている
- [ ] 退勤再確認時間は `2分` で固定されている
- [ ] 仕事場半径の既定値と許容範囲が確定している
- [ ] 修正履歴は履歴テーブル（append-only）方針で確定している
- [ ] 出力仕様（CSV/PDFの列定義と整合性ハッシュ項目）が確定している
