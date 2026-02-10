# GeoKintai 仕様書 (Draft)

## 1. 概要
GPS位置情報を使用し、当該ユーザーの「仕事場」への到着と出発をバックグラウンドで自動的に記録するiOSアプリケーション。

## 2. コア機能
- **自動記録 (証拠能力重視)**:
    - アプリがバックグラウンド、または停止状態であっても、設定された仕事場の出入りを検知し記録する。
    - **誤検知防止**: 単に半径内に入っただけでなく、5分連続で滞在したことを条件に出勤を確定させるロジックを採用。
    - **退勤誤検知防止**: `didExitRegion` 直後は退勤を確定せず、再確認時間中（2分固定）も半径外にいる場合のみ退勤確定とする。
    - **詳細ログ保存**: 裁判等の証拠として使用できるよう、出退勤時刻だけでなく、判定の根拠となったGPS生データ（緯度・経度・精度・時刻）もバックグラウンドで保存する。
- **仕事場管理**:
    - **複数登録可能**: 本社、支社、現場など複数の拠点を登録可能にする。
    - **登録方法**:
        1. 現在地から登録
        2. 地図上でピンをドロップして登録 ("Drop Pin")
    - **設定項目**: 名称、半径（デフォルト設定あり、個別調整可）。
- **履歴・エクスポート**:
    - 日次の出退勤記録表示。
    - **編集履歴の保持**: 手動修正を行った場合、元の自動記録データは上書きせず、履歴テーブルへ追記する（append-only）。
    - **レポート出力**: CSVまたはPDF形式で、稼働時間と詳細な位置情報ログを出力可能にする。
    - **証拠完全性**: エクスポート時に証拠データのハッシュ値と生成時刻を含め、後から改ざん検知できる形式を採用する。

## 3. UI/UX Flow (Native & Strict)
**Design Philosophy**: "Do not reinvent the wheel." 完全なiOS純正ルック＆フィールを目指す。カスタムモディファイアや固定サイズ指定は禁止。
- **Components**:
    - `List` + `.listStyle(.insetGrouped)` を基本構造とする。
    - `NavigationLink`, `Button` 等の標準コンポーネントをそのまま使用する。
    - フォントはすべて `.font(.headline)`, `.font(.body)`, `.font(.caption)` 等の **Dynamic Type 対応システムフォント**を使用。
    - 色指定も `Color.primary`, `Color.secondary`, `Color.systemBackground` などのセマンティックカラーを使用。

- **Tab 1: Status (ホーム)**
    - `.insetGrouped` リスト内で、現在のステータスをセクションとして表示。
    - アクション（出勤/退勤）もリスト内のボタン行として配置。
    - ミニマップもセクション内に埋め込む。
- **Tab 2: History (履歴)**
    - 標準的なリスト表示。セルレイアウトは `VStack(alignment: .leading)` 等でシンプルに組む。
    - 日付セクションを用いたグルーピング。
- **Tab 3: Settings (設定)**
    - 純正「設定アプリ」と同様の階層構造と見た目。
    - 仕事場編集画面も `Form` を使用し、標準的な入力フォームとする。

## 4. データモデル (Core Data / SwiftData)
堅牢性を担保するため、リレーショナルな構造を採用。

### 1. Workplace (仕事場)
管理対象となる拠点。
| Field | Type | Attributes | Description |
|---|---|---|---|
| id | UUID | Primary Key | 一意の識別子 |
| name | String | Required | 名称 (例: 本社) |
| kLatitude | Double | Required | 拠点中心の緯度 |
| kLongitude | Double | Required | 拠点中心の経度 |
| radius | Double | Default: 100.0 | 監視半径 (メートル) |
| monitoringEnabled | Bool | Default: true | 監視対象かどうか |
| createdAt | Date | | 作成日時 |

### 2. AttendanceRecord (出退勤記録)
1回の出勤〜退勤を表すトランザクションデータ。
| Field | Type | Attributes | Description |
|---|---|---|---|
| id | UUID | Primary Key | 一意の識別子 |
| workplaceId | UUID | Foreign Key | 関連する仕事場ID |
| entryTime | Date | Required | 到着確定時刻（進入検知時刻） |
| exitTime | Date | Optional | 出発確定時刻（nilの場合は勤務中） |
| isManual | Bool | Default: false | 表示最適化用フラグ（修正履歴がある場合true） |
| note | String? | Optional | 直近修正の要約メモ（正本は修正履歴テーブル） |
| createdAt | Date | Required | 作成日時 |

### 3. AttendanceCorrection (修正履歴)
`AttendanceRecord` と 1対多 で紐付く、手動修正の監査ログ。  
レコードは追記のみで、更新・削除しない（append-only）。
| Field | Type | Attributes | Description |
|---|---|---|---|
| id | UUID | Primary Key | 一意の識別子 |
| recordId | UUID | Foreign Key | 対象の出退勤レコードID |
| previousEntryTime | Date? | Optional | 修正前の出勤時刻 |
| previousExitTime | Date? | Optional | 修正前の退勤時刻 |
| newEntryTime | Date? | Optional | 修正後の出勤時刻 |
| newExitTime | Date? | Optional | 修正後の退勤時刻 |
| reason | String | Required | 修正理由（必須） |
| editedAt | Date | Required | 修正日時 |
| editorType | Enum | Required | 修正者種別（User / System） |
| integrityHash | String | Required | 行データの整合性検証用ハッシュ |

### 4. LocationProof (証拠ログ)
`AttendanceRecord` と 1対多 で紐付く、バックグラウンドで収集した生データ。
裁判等での証拠能力を担保するため、可能な限り生のGPS値を保存する。
| Field | Type | Attributes | Description |
|---|---|---|---|
| id | UUID | Primary Key | 一意の識別子 |
| recordId | UUID | Foreign Key | 親レコードID |
| timestamp | Date | Required | 取得日時 |
| latitude | Double | Required | 緯度 (WGS84) |
| longitude | Double | Required | 経度 (WGS84) |
| accuracy | Double | Required | 水平精度 (m) - 値が小さいほど高精度 |
| altitude | Double | Optional | 高度 - 建物の何階にいたかの推測用 |
| speed | Double | Optional | 移動速度 (m/s) - 車か徒歩かの判定用 |
| reason | Enum | Required | 記録理由 (EntryTrigger / StayCheck / ExitCheck) |
| capturedAtUtc | Date | Required | UTC基準の取得時刻（表示はローカル変換） |
| integrityHash | String | Required | 行データの整合性検証用ハッシュ |

## 5. 技術選定 (Technical Stack)
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Location API Service**: `CLLocationManager`, `CLRegionMonitoring` (Reliability重視のためCLMonitorは見送り)
    - **Background Policy**: `CLRegion`でWake up -> `startUpdatingLocation`で5分間高精度記録 -> Stop。
    - **Blue Bar**: `Authorized Always` 権限を取得し、標準では非表示にする(`showsBackgroundLocationIndicator = false`)。
- **Database**: Core Data (または SwiftData)
    - 理由: データの整合性と検索性を重視。CSV等のフラットファイルより堅牢。
    - 方針: 監査性のため `AttendanceCorrection` / `LocationProof` は改ざん検知可能なハッシュ付き追記モデルを採用。
