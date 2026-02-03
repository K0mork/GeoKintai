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

- [ ] **Phase 2: UI Implementation**
    - [ ] 詳細: [02_ui_implementation.md](docs/tasks/02_ui_implementation.md)
    - [x] Dashboard (Status)
    - [ ] History (List/Detail)
    - [ ] Settings (Workplace Management)

- [ ] **Phase 3: Integration & Verification**
    - [ ] 詳細: [03_integration.md](docs/tasks/03_integration.md)
    - [ ] 結合テスト (Location Service <-> Core Data)
    - [ ] シミュレータ検証 (GPX使用)
    - [ ] 実機検証
