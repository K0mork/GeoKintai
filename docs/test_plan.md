# Test Plan & Simulator Guide

## 概要
GeoKintaiのバックグラウンド位置連動機能（ジオフェンス進入→滞在監視→出勤確定）を、実機を持たずにXcodeシミュレータのみで検証する手順書。

## 1. テスト準備 (GPXファイルの作成)
Xcodeのシミュレータは、GPX（GPS Exchange Format）ファイルを読み込むことで、任意の場所や経路を移動させることができる。

### 必要なGPXファイル
以下の3パターンを `SimulatedLocations/` フォルダ（要作成）に用意する。

1.  **Workplace.gpx** (固定点)
    -   仕事場の中心座標 (例: 東京駅 35.6812, 139.7671)
    -   用途: 仕事場登録時のピン位置確認用。
2.  **Commute_In.gpx** (移動経路: 進入)
    -   仕事場から1km離れた地点 → 仕事場の中心まで移動して停止。
    -   用途: 出勤検知のテスト。
3.  **Pass_By.gpx** (移動経路: 通過)
    -   仕事場の半径内を通過し、停止せずに通り過ぎる。
    -   用途: 誤検知（通過しただけでは出勤にならない）の確認。

### GPXファイルの例 (`SimulatedLocations/Commute_In.gpx`)
```xml
<?xml version="1.0"?>
<gpx version="1.1" creator="Xcode">
    <!-- 1. Start point (1km away) -->
    <wpt lat="35.6890" lon="139.7570">
        <time>2024-01-01T09:00:00Z</time>
    </wpt>
    <!-- ... Intermediate points ... -->
    <!-- N. Arrival at Workplace -->
    <wpt lat="35.6812" lon="139.7671">
        <time>2024-01-01T09:10:00Z</time> <!-- 10 mins later -->
    </wpt>
     <!-- Stay there -->
    <wpt lat="35.6812" lon="139.7671">
        <time>2024-01-01T09:20:00Z</time> <!-- Stay for 10 mins -->
    </wpt>
</gpx>
```

## 2. Xcodeでの実行手順

### 手順A: デバッグ実行中の操作
1.  アプリをSimulaterで起動（**Debugモード**）。
2.  Xcodeのメニューバー `Debug` > `Simulate Location` を選択。
3.  `Add GPX File to Workspace...` から作成したGPXを選択。
4.  シミュレーションが開始され、青い矢印（現在地）が動き出す。

### 手順B: バックグラウンド動作の確認
1.  `Status` タブで監視が有効になっていることを確認。
2.  一度、ホーム画面に戻る（`Shift + Command + H`）。
3.  `Simulate Location` で `Commute_In` を再生開始。
4.  **期待される挙動**:
    -   5分〜10分後（GPXの時間経過による）、アプリから通知が届く、または再度アプリを開くと「出勤」になっている。
    -   Xcodeのコンソールログに `didEnterRegion`, `startUpdatingLocation`, `Stay Confirmed` 等のログが出力される。

## 3. テストシナリオ一覧

| ID | シナリオ名 | 使用GPX | 手順 | 期待値 |
|---|---|---|---|---|
| T-001 | 正常な出勤 | Commute_In | バックグラウンドで再生開始し、到着地点で5分以上待機 | ステータスが「勤務中」になり、ログに記録が残る |
| T-002 | 通過のみ | Pass_By | バックグラウンドで再生、通過して遠ざかる | ステータスは「退勤中」のまま変化しない |
| T-003 | アプリキル後の検知 | Commute_In | アプリをタスクキルしてから再生 | (OS依存のためシミュレータでは再現不可の場合あり。実機推奨) |
| T-004 | 正常な退勤 | Commute_Inの逆 | 勤務中状態から開始し、離脱するGPXを再生 | ステータスが「退勤中」になり、退勤時刻が記録される |

## 4. プロジェクト構成への反映
プロジェクトルートに `SimulatedLocations/` ディレクトリを作成し、テスト用GPXファイルを格納することを推奨する。
（Git管理に含めることで、チーム全員が同じテストを行える）
