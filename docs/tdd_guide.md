# TDD実行ガイド

この文書は、1機能スライスを Red-Green-Refactor で進めるための実務手順を定義する。  
上位規約は [tdd_rules.md](tdd_rules.md) とする。

## 1. 1サイクルの標準手順
1. 対象を固定する（`FR-*` と `AC-*` を1セット選ぶ）。
2. Red を作る（失敗するユニットテストを1件追加）。
3. Green にする（最小実装で当該テストのみ通す）。
4. Refactor する（命名/重複/責務を改善）。
5. 全関連テストを再実行する。
6. `requirements_traceability.md` を更新する。

## 2. テスト設計の最小ルール
- 命名: `test_<対象>_<条件>_<期待結果>()`
- 原則: 1テスト1期待
- 優先観点: 正常系 -> 境界値 -> 異常系
- テスト本文またはコメントで `AC-*` を追跡できるようにする

例: `test_stayVerifier_whenInsideFor5Minutes_returnsConfirmed()`

## 3. テストダブル方針
- `CLLocationManager`, `Date`, `Timer` は抽象化し注入する。
- モックは最小振る舞いのみ再現する。
- `sleep` 依存のテストは禁止し、仮想時刻で制御する。

## 4. 先に固定するインターフェース
- `Clock`: 現在時刻取得
- `LocationProvider`: 位置イベント通知
- `RegionMonitor`: リージョン監視開始/停止
- `AttendanceStore`: 出退勤レコード永続化
- `ProofStore`: 位置証拠ログ永続化

## 5. Definition of Done（機能スライス）
- 対応する `AC-*` がテストで検証されている。
- Red から Green への遷移が確認できる。
- 既存テストを壊していない。
- `requirements_traceability.md` が最新化されている。

## 6. 開始前チェック
- [ ] 滞在判定時間 `5分` が設定されている
- [ ] 退勤再確認時間 `2分` が設定されている
- [ ] 仕事場半径の既定値が `100m` である
- [ ] 修正履歴が append-only 方針である
- [ ] エクスポート項目（証拠・ハッシュ）が定義済みである

## 7. 失敗時の判断
- Red が想定外の理由で失敗した場合は、要件解釈かテスト条件を先に修正する。
- Green で既存テストが落ちた場合は回帰として最優先で解消する。
- 設計が複雑化した場合は、先にインターフェース分割を行ってから実装を進める。

## 8. 関連文書
- [tdd_rules.md](tdd_rules.md)
- [testing_strategy.md](testing_strategy.md)
- [simulator_test_plan.md](simulator_test_plan.md)
