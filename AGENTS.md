# AGENTS.md

このファイルは、Codex がこのリポジトリで安全かつ一貫して作業するための運用ルールです。

## 適用範囲
- この `AGENTS.md` はリポジトリルート配下全体に適用します。
- サブディレクトリに別の `AGENTS.md` がある場合は、より近い階層の指示を優先します。
- 指示の優先順は「近い `AGENTS.md` > ルート `AGENTS.md` > 各種ドキュメント」とします。

## プロジェクト概要
- iOS アプリ本体: `App/GeoKintaiApp`
- ドメイン/コアロジック: `Sources/geoKintai`
- テスト: `App/GeoKintaiAppTests`, `Tests/geoKintaiTests`
- 仕様・テスト運用: `docs/`

## ブランチ戦略
- 基本は `master` から作業ブランチを作成する。
- ブランチ名は必ず `codex/` プレフィックスを使う。
- 1ブランチ1目的（機能追加、バグ修正、ドキュメント更新を混在させない）。
- 命名は `codex/<type>-<scope>-<summary>` の kebab-case を使う。
- `type` は `fix` `feat` `refactor` `docs` `test` `chore` を使う。
- 例:
  - `codex/fix-settings-workplace-edit-tap`
  - `codex/docs-testing-strategy-update`
- `master` への直接コミット・直接 push は行わない（PR 経由）。
- 変更が肥大化したら、目的単位でブランチを分割する。

## コミット戦略
- 1コミット1目的を厳守する。
- フォーマット変更は機能変更と分離する。
- コミットメッセージは Conventional Commits を使う。
  - 例: `fix: 編集タップで削除が発火する不具合を修正`
  - 例: `docs: AGENTS.md にブランチ戦略を追加`
- 無関係な差分（IDE自動変更など）はコミットに含めない。

## Codex 作業フロー
1. 影響範囲を `rg` で特定し、対象ファイルだけを読む。
2. 変更前に `git status --short` を確認し、既存の差分を把握する。
3. 最小差分で実装し、意図が伝わりにくい箇所だけ短いコメントを入れる。
4. 変更に応じたテスト/ビルドを実行する。
5. 実行コマンドと結果を要約して報告する。

## 検証コマンド
- コアロジック変更時:
  - `swift test`
- App/UI 変更時（最低限）:
  - `xcodebuild -scheme GeoKintaiApp -destination "platform=iOS Simulator,id=<simulator_udid>,arch=arm64" build`
- 変更範囲が広い時:
  - `./scripts/run_all_checks.sh <simulator_udid>`

## ドキュメント同期
- 要件・受け入れ基準・テスト計画に影響する変更では、必要に応じて以下を同時更新する。
  - `docs/specification.md`
  - `docs/acceptance_criteria.md`
  - `docs/requirements_traceability.md`
  - `docs/testing_strategy.md`

## 禁止事項
- `git reset --hard` などの破壊的操作を許可なく実行しない。
- ユーザーが作成した未関連のローカル差分を巻き戻さない。
- 失敗した検証を黙ってスキップしない（未実施・失敗は明示する）。
