# コードスキャン（CodeQL）について

## 現状

このリポジトリでは CodeQL の default setup を **無効化** しています（2026-08-08）。

## 理由

CodeQL は Dart をサポートしていません。本プロジェクトの実装は `lib/` 配下の
Dart 50 ファイルであり、解析対象になりません。

一方 default setup は、Flutter が生成したプラットフォーム側のひな形を検出して
Swift / Java-Kotlin / Ruby の解析を試み、いずれも失敗していました。

| 言語 | 検出された対象 | 失敗理由 |
|---|---|---|
| Swift | `ios/Runner/{AppDelegate,SceneDelegate}.swift`、`ios/RunnerTests/` 計 34 行 | Flutter のツールチェーン無しでは Runner プロジェクトをビルドできない |
| Java-Kotlin | `MainActivity.kt` 5 行、`GeneratedPluginRegistrant.java` 69 行（自動生成） | 同上（Gradle + Flutter が必要） |
| Ruby | `ios/Podfile`、`.ruby-lsp/Gemfile` | `CodeQL detected code written in Java/Kotlin, Swift, GitHub Actions and C/C++, but not any written in Ruby`（Ruby のソースが存在しない） |

対象は合計 108 行、しかもすべて Flutter が生成したひな形です。ビルド環境を
整えてまで解析しても、得られる知見はありません。GitHub Actions のワークフローも
存在しないため `actions` の解析対象もありません。

## 再度有効化する条件

次のいずれかに当てはまったら、advanced setup（Flutter のセットアップを含む
ワークフロー）の導入を検討してください。

- プラットフォームチャネル等で Swift / Kotlin の実装コードを自前で書き始めたとき
- `.github/workflows/` を追加したとき（`actions` の解析だけでも価値がある）
- CodeQL が Dart をサポートしたとき

## Dart 側の静的解析

Dart のコード品質は `analysis_options.yaml` に基づく `flutter analyze` で
担保しています。`make` のターゲットを参照してください。
