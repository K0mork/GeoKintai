# Phase 1: Core Logic 実装タスク

目的: ドメインロジックと永続化層を TDD で確立する。

## 1. セットアップ
- [x] P1-001 Xcode プロジェクトと Test Target を作成
- [x] P1-002 `Info.plist` に位置権限文言を設定
- [x] P1-003 Background Modes（Location Updates）を有効化

## 2. 永続化層
- [x] P1-010 `Workplace` エンティティ定義（FR-01, FR-07）
- [x] P1-011 `AttendanceRecord` エンティティ定義（FR-02, FR-04, FR-05）
- [x] P1-012 `AttendanceCorrection` エンティティ定義（FR-06, NFR-04）
- [x] P1-013 `LocationProof` エンティティ定義（FR-02, FR-04, NFR-03）
- [x] P1-014 `PersistenceControllerTests` を Red で作成
- [x] P1-015 `PersistenceController` を Green で実装

## 3. リポジトリ
- [x] P1-020 `WorkplaceRepositoryTests` -> `WorkplaceRepository` 実装
- [x] P1-021 `AttendanceRepositoryTests` -> 勤務中一意制約実装（FR-05）
- [x] P1-022 `AttendanceCorrectionRepositoryTests` -> append-only 実装（FR-06）
- [x] P1-023 `LocationProofRepositoryTests` -> 証拠ログ保存実装

## 4. ドメイン判定
- [x] P1-030 `StayVerifierTests` -> 5分滞在判定実装（FR-02, FR-03）
- [x] P1-031 `ExitVerifierTests` -> 2分再確認判定実装（FR-04）
- [x] P1-032 `Clock` 抽象化と仮想時刻テスト導入（NFR-02）

## 5. 監査・整合性
- [x] P1-050 修正履歴の hash 生成テストと実装（FR-06, FR-10）
- [x] P1-051 証拠ログ hash 生成テストと実装（FR-10）
- [x] P1-060 append-only ガードのテストと実装（NFR-04）

## 6. 時刻整合性
- [x] P1-070 UTC 保存/表示変換テストを追加（NFR-01）

## 7. 完了条件
- [x] Phase1 対象 `P1-*` が完了
- [x] `FR-01`〜`FR-07`, `FR-10` の対応テストがグリーン
- [x] `requirements_traceability.md` の状態が更新されている
