# GeoKintai Project ToDo

本プロジェクトの進捗管理用ドキュメント。

## 0. Documentation & Planning
- [x] **仕様策定**
    - [x] `docs/specification.md` 作成 (UI/Data Model)
    - [x] `docs/logic_flow.md` 作成 (Sequence Diagram)
    - [x] `docs/test_plan.md` 作成 (Simulator Test Guide)

## 0. Development Guidelines
- See [development_rules.md](docs/development_rules.md) for TDD workflow.

## 1. Implementation Phase
詳細なタスクは `docs/tasks/` 以下のファイルで管理する。

- [x] **Phase 1: Project Setup & Core Logic**
    - [x] 詳細: [01_core_logic.md](docs/tasks/01_core_logic.md)
    - [x] プロジェクト雛形作成 (Include Test Target)
    - [x] Core Data Stack 実装 (TDD)
    - [x] LocationManager (バックグラウンド検知) 実装 (TDD)
    - [x] Repositories 実装 (TDD)

- [x] **Phase 2: UI Implementation**
    - [x] 詳細: [02_ui_implementation.md](docs/tasks/02_ui_implementation.md)
    - [x] Dashboard (Status) - TabView構造 + StatusTab
    - [x] History (List/Detail) - HistoryTab + HistoryDetailView
    - [x] Settings (Workplace Management) - SettingsTab + WorkplaceListView + WorkplaceEditView

- [x] **Phase 3: Integration & Verification**
    - [x] 詳細: [03_integration.md](docs/tasks/03_integration.md)
    - [x] 結合テスト (Location Service <-> Core Data)
    - [x] シミュレータ検証 (GPX使用) - SimulatedLocations/ に4つのGPXファイル作成
    - [x] 実機検証

## 2. Additional Features (実装済み)
- [x] LocationProofRepository (証拠ログ保存)
- [x] AppCoordinator (アプリ起動時の統合ロジック)
- [x] 位置情報権限リクエストUI (LocationPermissionView)
- [x] 滞在確認ロジック (5分タイマー)
- [x] Exit確認ロジック (2分タイマー)
- [x] Region Sync機能
