# ロジックフロー

GeoKintai の主要ドメインイベント（入域、滞在判定、退域、修正、エクスポート）の時系列を示す。  
詳細な合格条件は [acceptance_criteria.md](acceptance_criteria.md) を参照する。

## 1. 出勤確定フロー（FR-02 / FR-03）

```mermaid
sequenceDiagram
    participant OS as iOS CoreLocation
    participant App as GeoKintai
    participant Verifier as StayVerifier
    participant DB as Persistence

    OS->>App: didEnterRegion(workplace)
    App->>App: beginBackgroundTask()
    App->>App: startUpdatingLocation()
    App->>Verifier: start(window=5min, radius=workplace.radius)

    loop 監視中
        OS->>App: didUpdateLocations(sample)
        App->>Verifier: add(sample)
    end

    Verifier-->>App: 判定結果
    alt 半径内滞在が5分連続
        App->>DB: create AttendanceRecord(entryTime)
        App->>DB: append LocationProof(reason=StayCheck)
    else 途中離脱
        App->>App: 出勤確定しない
    end

    App->>App: stopUpdatingLocation()
    App->>App: endBackgroundTask()
```

## 2. 退勤確定フロー（FR-04）

```mermaid
sequenceDiagram
    participant OS as iOS CoreLocation
    participant App as GeoKintai
    participant Verifier as ExitVerifier
    participant DB as Persistence

    OS->>App: didExitRegion(workplace)
    App->>App: beginBackgroundTask()
    App->>App: startUpdatingLocation()
    App->>Verifier: start(window=2min, radius=workplace.radius)

    loop 再確認中
        OS->>App: didUpdateLocations(sample)
        App->>Verifier: add(sample)
    end

    Verifier-->>App: 判定結果
    alt 半径外が2分連続
        App->>DB: update AttendanceRecord(exitTime)
        App->>DB: append LocationProof(reason=ExitCheck)
    else 半径内へ戻る
        App->>App: 退勤確定しない
    end

    App->>App: stopUpdatingLocation()
    App->>App: endBackgroundTask()
```

## 3. 手動修正フロー（FR-06）

```mermaid
sequenceDiagram
    participant User as User
    participant UI as HistoryDetailView
    participant VM as HistoryDetailViewModel
    participant DB as Persistence

    User->>UI: 修正値と理由を入力
    UI->>VM: submitCorrection(recordId, newValues, reason)
    VM->>DB: fetch current AttendanceRecord
    VM->>DB: append AttendanceCorrection(before/after/reason/hash)
    VM->>DB: update AttendanceRecord(display fields)
    VM-->>UI: 成功レスポンス
    UI-->>User: 修正履歴を表示
```

## 4. エクスポートフロー（FR-08 / FR-10）

```mermaid
sequenceDiagram
    participant User as User
    participant UI as ExportView
    participant Service as ExportService
    participant DB as Persistence

    User->>UI: CSV/PDF出力を実行
    UI->>Service: buildExport(range, format)
    Service->>DB: fetch AttendanceRecord
    Service->>DB: fetch AttendanceCorrection
    Service->>DB: fetch LocationProof
    Service->>Service: calculate integrity hash
    Service-->>UI: file + metadata
    UI-->>User: 共有シート表示
```

## 5. 失敗時分岐
- 位置権限不足: 自動記録は停止し、設定導線を表示する（FR-09）。
- GPS 取得失敗: 現サイクルを中断し、次イベントで再試行する。既存データは保持する。
- 永続化失敗: ユーザー通知し、ログに失敗種別を記録する。

## 6. 関連文書
- [specification.md](specification.md)
- [acceptance_criteria.md](acceptance_criteria.md)
- [tdd_guide.md](tdd_guide.md)
- [simulator_test_plan.md](simulator_test_plan.md)
