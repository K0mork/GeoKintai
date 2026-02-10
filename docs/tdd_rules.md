# 開発規約（TDD）

この文書は、GeoKintai で守る不変ルールを定義する。  
運用手順は [tdd_guide.md](tdd_guide.md) を参照する。

## 1. 基本原則
1. Red: 先に失敗するテストを書く。
2. Green: 失敗したテストを通す最小実装だけを行う。
3. Refactor: 振る舞いを変えずに構造を改善し、全テストを再実行する。

## 2. 必須ルール
- テストなしで本実装を開始しない。
- `View` に業務ロジックを残さず、テスト可能な層へ分離する。
- 判定ロジックはユニットテストを必須とする。
- 変更した `FR/AC/T-*` 対応を `requirements_traceability.md` に反映する。
- コミット前に関連テストをグリーンにする。
- 機能追加とリファクタは可能な限りコミットを分離する。

## 3. 品質ゲート
- 追加要件に対して Red の失敗理由が妥当である。
- Green 実装が最小で、過剰実装がない。
- Refactor 後に既存テストを含めて回帰がない。
- 受け入れ基準（`AC-*`）を満たすテスト根拠が存在する。

## 4. 更新ルール
- 仕様変更時: `specification.md` + `acceptance_criteria.md` + `requirements_traceability.md`
- 運用変更時: `tdd_guide.md` + `testing_strategy.md`
- テストケース変更時: `simulator_test_plan.md` + `requirements_traceability.md`

## 5. レビュー観点
- 要件IDの対応が明示されているか。
- テスト名が振る舞いを説明しているか。
- 時刻依存テストが仮想時刻で制御されているか。
- append-only 制約を破る変更がないか。

## 6. 関連文書
- [tdd_guide.md](tdd_guide.md)
- [testing_strategy.md](testing_strategy.md)
- [acceptance_criteria.md](acceptance_criteria.md)
- [requirements_traceability.md](requirements_traceability.md)
