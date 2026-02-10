# 受け入れ基準（Implementation Gate）

本書は、`specification.md` で定義した要件を実装完了と見なす条件を定義する。  
記法は `Given / When / Then` を使用する。

## 1. 前提条件
- 位置情報権限の主系は `Always`。
- 仕事場半径の既定値は `100m`。
- 滞在判定時間は `5分`。
- 退勤再確認時間は `2分`。

## 2. 機能受け入れ基準（AC）

### AC-01 仕事場登録/編集/削除（FR-01）
- Given: ユーザーが設定画面にいる
- When: 仕事場を保存する
- Then: `name`, `latitude`, `longitude`, `radius`, `monitoringEnabled` が永続化される
- Then: 削除時は監視対象リージョンから除外される

### AC-02 出勤確定（FR-02）
- Given: 監視対象仕事場が有効で未勤務状態
- When: `didEnterRegion` 後、5分連続で半径内に滞在する
- Then: 出勤レコードが1件作成され `entryTime` が記録される
- Then: 判定根拠の位置サンプルが `LocationProof` に保存される

### AC-03 通過誤検知防止（FR-03）
- Given: 監視対象仕事場が有効
- When: 入域後5分未満で半径外に離脱する
- Then: 出勤レコードは作成されない

### AC-04 退勤確定（FR-04）
- Given: 勤務中レコード（`exitTime == nil`）がある
- When: `didExitRegion` 後、2分連続で半径外にいる
- Then: 既存レコードの `exitTime` が更新される
- Then: 退勤判定中サンプルが `LocationProof` に保存される
- Then: 判定中に半径内へ戻った場合は退勤確定しない

### AC-05 勤務中一意性（FR-05）
- Given: 同一仕事場に勤務中レコードが存在する
- When: 同仕事場で出勤確定処理が再実行される
- Then: 新規勤務中レコードは作成されない

### AC-06 手動修正監査（FR-06）
- Given: 自動記録済みレコードがある
- When: ユーザーが時刻を手動修正する
- Then: 元データは直接上書きせず `AttendanceCorrection` に追記される
- Then: 修正理由、修正前後値、修正日時、整合性ハッシュが記録される

### AC-07 複数仕事場独立性（FR-07）
- Given: 複数仕事場が登録済み
- When: 複数リージョンで出退勤イベントが発生する
- Then: 記録は `workplaceId` ごとに分離される

### AC-08 エクスポート完全性（FR-08）
- Given: 出退勤記録と証拠ログがある
- When: CSV または PDF を出力する
- Then: 退勤記録、修正履歴、位置証拠、生成時刻、整合性ハッシュを含む
- Then: 出力失敗時は失敗理由がユーザーに提示される

### AC-09 権限不足時安全動作（FR-09）
- Given: 位置権限が `When In Use` または `Denied`
- When: バックグラウンド記録が必要な状態になる
- Then: 自動記録は実行されない
- Then: 権限設定への導線が表示される
- Then: 既存データは破損しない

### AC-10 改ざん検知（FR-10）
- Given: 記録済みまたはエクスポート済みデータがある
- When: 整合性チェックを実行する
- Then: ハッシュ不一致を検知できる
- Then: 不一致レコードを識別表示できる

## 3. 非機能受け入れ基準（NFC）
- NFC-01（NFR-01）: 永続化は UTC 基準で行い、表示時のみローカル変換する。
- NFC-02（NFR-02）: 滞在判定/退勤判定/重複防止がユニットテストで再現可能である。
- NFC-03（NFR-03）: 位置証拠ログから対象レコードを追跡できる。
- NFC-04（NFR-04）: 監査ログは追記型で、更新/削除に依存しない。
- NFC-05（NFR-05）: 主要イベントログが確認できる。
- NFC-06（NFR-06）: 異常系でも既存データを破損しない。

## 4. 判定ルール
- すべての `AC-*` と `NFC-*` を満たしたときのみ機能を「受け入れ可」とする。
- 判定根拠は `requirements_traceability.md` に記録されたテストケースに基づく。

## 5. 関連文書
- [specification.md](specification.md)
- [requirements_traceability.md](requirements_traceability.md)
- [testing_strategy.md](testing_strategy.md)
- [simulator_test_plan.md](simulator_test_plan.md)
