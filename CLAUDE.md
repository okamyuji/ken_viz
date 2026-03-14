# KenViz - Claude Code 開発指示書

> **最終更新:** 2026-03-15
> **プロジェクトパス:** `/Users/yujiokamoto/devs/flutter_app/ken_viz`

---

## 1. プロジェクト概要

KenViz（健Viz）は、健康診断結果をスマートフォンのカメラで撮影し、OCRで読み取り、ローカルのみでデータを保存・可視化するFlutterアプリ。外部通信は一切行わない（Privacy by Design）。

### コアコンセプト

- 完全オンデバイス処理（OCR・保存・可視化・PDF生成）
- google_mlkit_text_recognition による日本語OCR
- 撮影 → OCR → パーサー → 確認/修正UI → ローカルDB → チャート描画
- 共有はOS標準のShare Sheet経由（PDF/画像/JSON）

---

## 2. 技術スタック

| 技術 | バージョン | 用途 |
| --- | --------- | --- |
| Flutter | 3.41.2 (fvm固定) | UIフレームワーク |
| flutter_riverpod | ^3.3.1 | 状態管理（Provider直接利用、コード生成なし） |
| Drift + sqlite3_flutter_libs | ^2.32.0 | ローカルDB（Isarから移行済み） |
| google_mlkit_text_recognition | ^0.15.1 | オンデバイスOCR（日本語対応） |
| fl_chart | ^0.70.2 | チャート描画 |
| go_router | ^17.1.0 | ナビゲーション |
| image_picker + image | ^1.1.0 / ^4.5.0 | カメラ撮影・画像前処理 |
| local_auth | ^2.3.0 | バイオメトリクス認証 |
| share_plus | ^10.1.4 | OS Share Sheet |
| pdf + printing | ^3.11.0 / ^5.13.0 | PDFレポート生成 |

---

## 3. アーキテクチャ

### レイヤー構成（Clean Architecture）

```text
Presentation (Pages / Providers)
       ↓
Application (UseCases / Services)
       ↓
Domain (Entities / ValueObjects / Repository IF)
       ↓
Infrastructure (Drift DB / ML Kit / Parsers)
```

### データフロー

```text
カメラ/ギャラリー
  → ImagePreprocessor（グレスケ、コントラスト強調）
  → OcrEngine (ML Kit on-device)
  → ParserFactory（フォーマット自動判定）
    ├─ TableVerticalParser (タイプA)
    └─ FreetextParser (タイプC / フォールバック)
  → ItemMatcher（マスタと3段階ファジーマッチ）
  → OcrConfirmPage（ユーザー確認・修正 + 保存時再マッチング）
  → DriftRepository（SQLite永続化）
  → Dashboard / Charts（fl_chart描画）
```

### 重要な設計判断

| 判断 | 理由 |
| ---- | --- |
| Drift（Isarから移行） | Isar 3.xがFlutter 3.41と非互換。DriftはSQLiteベースで安定 |
| Riverpod Provider直接利用 | コード生成（riverpod_generator）は未使用。手動Provider定義 |
| Strategy + Factory パターン（パーサー） | フォーマット追加が容易 |
| 保存時ItemMatcher再マッチング | OCRのmatchedItemCode欠落時にも一貫したitemCodeを保証 |
| ML Kit初回モデルDL | 専用のモデルDL画面（model_download_page）で対応 |

---

## 4. プロジェクト構造

```text
lib/
├── main.dart                                    # エントリーポイント
├── app.dart                                     # MaterialApp + テーマ
├── core/
│   ├── constants/test_item_defaults.dart         # マスタデータ28項目 × 8カテゴリ
│   └── utils/text_normalizer.dart               # 全角→半角、Levenshtein距離
├── domain/
│   ├── entities/                                # Profile, Checkup, TestResult, TestItemMaster
│   ├── value_objects/value_objects.dart          # ReferenceRange, ConfidenceScore, ParsedField
│   └── repositories/repositories.dart           # 全リポジトリIF
├── application/
│   ├── services/
│   │   ├── ocr_service.dart                     # OCR + パース統合
│   │   ├── image_preprocessor.dart              # 画像前処理
│   │   └── pdf_generator_service.dart           # PDF生成
│   └── usecases/
│       ├── get_dashboard_usecase.dart           # ダッシュボード集計
│       ├── get_trend_chart_usecase.dart          # トレンドチャートデータ
│       ├── export_pdf_usecase.dart              # PDFエクスポート
│       └── share_chart_usecase.dart             # チャート共有
├── infrastructure/
│   ├── datasources/drift/
│   │   ├── app_database.dart                    # Driftスキーマ定義（5テーブル）
│   │   ├── app_database.g.dart                  # 生成コード（git除外）
│   │   └── database_provider.dart               # DB初期化 + マスタ投入
│   ├── ocr/
│   │   ├── ocr_engine.dart                      # OCR抽象IF
│   │   ├── mlkit_ocr_engine.dart                # ML Kit実装
│   │   └── ocr_model_service.dart               # モデルDL管理
│   ├── parsers/
│   │   ├── parser_strategy.dart                 # Strategy IF + OcrTextResult
│   │   ├── parser_factory.dart                  # フォーマット自動判定
│   │   ├── item_matcher.dart                    # 3段階マッチング
│   │   ├── table_vertical_parser.dart           # タイプA 縦型表
│   │   ├── freetext_parser.dart                 # タイプC フリーテキスト
│   │   ├── spatial_row_reconstructor.dart       # OCR空間配置→行再構成
│   │   └── parsed_checkup_result.dart           # パース結果構造体
│   ├── repositories/                            # Drift Repository実装 × 4
│   └── security/app_lock_service.dart           # バイオメトリクス認証
└── presentation/
    ├── router/app_router.dart                   # go_router設定
    ├── providers/
    │   ├── repository_providers.dart            # DB/Repository Provider
    │   ├── ocr_providers.dart                   # OCR + パース結果 Provider
    │   └── dashboard_providers.dart             # ダッシュボード Provider
    └── pages/
        ├── dashboard_page.dart                  # ホーム（カテゴリ別サマリー）
        ├── scan_page.dart                       # カメラ撮影
        ├── ocr_confirm_page.dart                # OCR結果確認・修正 + 上書き保存
        ├── manual_input_page.dart               # 手動入力
        ├── history_list_page.dart               # 健診履歴（スワイプ削除対応）
        ├── checkup_detail_page.dart             # 全項目一覧
        ├── chart_detail_page.dart               # fl_chart トレンドグラフ
        ├── model_download_page.dart             # OCRモデルDL画面
        ├── settings_page.dart                   # 設定
        ├── lock_page.dart                       # アプリロック
        └── share_page.dart                      # 共有
```

---

## 5. 開発ルール

### ビルド・検証サイクル

コード変更のたびに:

```bash
fvm dart format .                # フォーマット
fvm flutter analyze              # 静的解析（strict mode）
fvm flutter test                 # テスト（現在124ケース）
```

IPAビルド（コード署名付き）:

```bash
fvm flutter build ipa --export-method development
```

### コーディング規約

- `analysis_options.yaml` の strict モード厳守（strict-casts/inference/raw-types）
- 生成コード（`*.g.dart`）はgit管理しない
- 各ファイル先頭にドキュメントコメントで設計ID（[DE-01]、[UC-01]等）を記載
- 日本語コメントで意図を記述
- itemCodeは必ずItemMatcher経由でマスタIDに正規化すること（OCR/手動入力共通）

### テスト（124ケース）

| ファイル | テスト内容 |
| ------- | --- |
| `test/domain/value_objects_test.dart` | ReferenceRange判定、境界値、ConfidenceScore |
| `test/infrastructure/text_normalizer_test.dart` | 全角変換、数値抽出、Levenshtein距離 |
| `test/infrastructure/parsers/item_matcher_test.dart` | 3段階マッチング、表記揺れ14パターン |
| `test/infrastructure/parsers/table_vertical_parser_test.dart` | 各種区切り、全角数字、16項目総合 |
| `test/infrastructure/repositories/drift_repositories_test.dart` | Drift CRUD操作 |
| `test/presentation/dashboard_page_test.dart` | ダッシュボードWidget |
| `test/presentation/manual_input_page_test.dart` | 手動入力Widget |
| `test/presentation/settings_page_test.dart` | 設定画面Widget |

---

## 6. 完了済み作業

Sprint 1〜4 は全て完了:

- **Sprint 1** ビルド基盤: fvm, pub get, analyze, test, build 全パス
- **Sprint 2** DB + Repository: Drift（Isarから変更）スキーマ定義、Repository実装 × 4、マスタデータ投入
- **Sprint 3** カメラ + OCR統合: ML Kit実装、画像前処理、OCR→パース→確認UI→DB保存の一気通貫フロー
- **Sprint 4** ダッシュボード + チャート: カテゴリ別サマリー、fl_chart折れ線グラフ（基準範囲バンド付き）、go_router、ボトムナビ

---

## 7. 残作業（Phase 1 MVP）

### 品質改善

- チャート描画の改善（X軸の回数表示、Y軸の正規化 — HDL_C等の小レンジ項目）
- TableHorizontalParser（タイプB）の実装
- 検査項目マスタのエイリアス拡充（実データでのテスト）

### Sprint 5: セキュリティ + 共有（未着手）

- `lock_page.dart` — バイオメトリクス/PIN認証UI（サービス層は実装済み）
- `share_page.dart` — 共有範囲選択、プレビュー、個人情報除外オプション
- PDF生成の統合テスト

### その他

- Widgetテスト + ゴールデンテスト拡充
- 統合テスト（E2E: 撮影→保存→表示フロー）
- freezed によるイミュータブルモデル化（現在は手動copyWith）

---

## 8. 既知の課題

| 課題 | 対応方針 |
| ---- | ------ |
| ML Kit初回モデルDL時のネットワーク許可 | model_download_page で明示的にDL後、通常使用時はオフライン |
| `image`パッケージの前処理パフォーマンス | 重い場合は`compute()`でIsolateに逃がす |
| 検査項目マスタの網羅性 | 実際の健診結果でテストし、不足エイリアスを追加 |
| 同一checkup重複取り込み | 上書き保存ダイアログ + 履歴スワイプ削除で対応済み |

---

## 9. 参照ドキュメント

- `docs/01_requirements.md` — ユースケース詳細、非機能要件、画面構成
- `docs/02_design.md` — モジュール構成、パーサーフロー、テスト戦略
- `docs/03_traceability.md` — UC→設計→テストの完全マッピング
