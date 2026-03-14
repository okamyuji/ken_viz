# KenViz 設計書

> **Version:** 1.0
> **Date:** 2026-03-11
> **Status:** Draft
> **Author:** Yuji
> **前提ドキュメント:** 01_requirements.md (要件仕様書 v1.0)

---

## 1. 設計方針

### 1.1 アーキテクチャ原則

| 原則 | 説明 |
|---|---|
| Privacy by Design | 全処理をオンデバイスで完結。ネットワーク通信レイヤーを持たない |
| Clean Architecture | Presentation / Application / Domain / Infrastructure の4層分離 |
| Testability First | 各層の依存を抽象化し、単体テスト・Widgetテストを容易にする |
| Progressive Enhancement | OCRフォーマット対応をプラグイン方式で段階追加可能にする |
| Fail-Safe UX | OCR失敗時は必ず手動入力へフォールバック。データ欠損を防ぐ |

### 1.2 設計判断ログ (ADR)

| ID | 決定事項 | 理由 | 代替案 |
|---|---|---|---|
| ADR-01 | 状態管理にRiverpod 3.xを採用 | コード生成による型安全、テスタビリティ、Flutter公式推奨に近い | Bloc（ボイラープレート過多）、Provider（型安全性不足） |
| ADR-02 | ローカルDBにIsarを採用 | Dart-nativeで高速、複合インデックス対応、スキーママイグレーション有 | sqflite（SQL記述負荷）、Hive（インデックス弱い） |
| ADR-03 | OCRにML Kitを採用 | オンデバイス日本語対応、Googleの継続メンテナンス | Tesseract（Flutter統合が不安定） |
| ADR-04 | パーサーをStrategy Pattern で実装 | フォーマットごとのロジック分離、新規フォーマットの追加が容易 | 単一パーサー（拡張困難） |
| ADR-05 | 共有はOS標準Share Sheetのみ | 外部サービス依存なし、ユーザーの送信先選択を尊重 | アプリ内メール送信（権限・依存増） |

---

## 2. システムアーキテクチャ

### 2.1 レイヤーアーキテクチャ

```
┌──────────────────────────────────────────────────┐
│                  Presentation Layer               │
│  Widgets / Pages / ViewModels (Riverpod)          │
├──────────────────────────────────────────────────┤
│                  Application Layer                │
│  UseCases / Services                              │
├──────────────────────────────────────────────────┤
│                  Domain Layer                     │
│  Entities / ValueObjects / Repository Interfaces  │
├──────────────────────────────────────────────────┤
│                Infrastructure Layer               │
│  Isar Repos / ML Kit / Camera / FileSystem / PDF  │
└──────────────────────────────────────────────────┘
```

### 2.2 モジュール構成

```
lib/
├── main.dart
├── app.dart                         # MaterialApp + Router設定
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # カラーパレット定義
│   │   ├── app_theme.dart           # ThemeData (Light/Dark)
│   │   └── test_item_defaults.dart  # 検査項目マスターデータ
│   ├── errors/
│   │   ├── app_exception.dart       # 共通例外クラス
│   │   └── failure.dart             # Failure sealed class
│   ├── extensions/
│   │   ├── date_ext.dart
│   │   └── string_ext.dart
│   └── utils/
│       ├── decimal_util.dart        # 数値精度ユーティリティ
│       └── logger.dart
│
├── domain/
│   ├── entities/
│   │   ├── profile.dart             # [DE-01]
│   │   ├── checkup.dart             # [DE-02]
│   │   ├── test_result.dart         # [DE-03]
│   │   ├── test_category.dart       # [DE-04]
│   │   └── test_item_master.dart    # [DE-05]
│   ├── value_objects/
│   │   ├── test_value.dart          # 検査値 + 単位のVO
│   │   ├── reference_range.dart     # 基準範囲VO
│   │   └── confidence_score.dart    # OCR信頼度VO
│   └── repositories/
│       ├── profile_repository.dart
│       ├── checkup_repository.dart
│       └── test_item_master_repository.dart
│
├── application/
│   ├── usecases/
│   │   ├── scan_checkup_usecase.dart        # [UC-01, UC-12]
│   │   ├── confirm_ocr_result_usecase.dart  # [UC-02]
│   │   ├── manual_input_usecase.dart        # [UC-03]
│   │   ├── get_dashboard_usecase.dart       # [UC-04]
│   │   ├── get_trend_chart_usecase.dart     # [UC-05, UC-06]
│   │   ├── export_pdf_usecase.dart          # [UC-07]
│   │   ├── share_chart_usecase.dart         # [UC-08]
│   │   ├── export_import_json_usecase.dart  # [UC-09]
│   │   └── manage_profile_usecase.dart      # [UC-11]
│   └── services/
│       ├── ocr_service.dart                 # ML Kit抽象化
│       ├── parser_service.dart              # パーサー統合
│       ├── image_preprocessor.dart          # 画像前処理
│       └── pdf_generator_service.dart       # PDFレンダリング
│
├── infrastructure/
│   ├── datasources/
│   │   ├── isar/
│   │   │   ├── isar_database.dart           # DB初期化・マイグレーション
│   │   │   ├── isar_profile_datasource.dart
│   │   │   ├── isar_checkup_datasource.dart
│   │   │   └── schemas/                     # Isarスキーマ定義
│   │   └── local_file_datasource.dart       # 画像・JSONファイル管理
│   ├── repositories/                        # Repository実装
│   │   ├── profile_repository_impl.dart
│   │   ├── checkup_repository_impl.dart
│   │   └── test_item_master_repository_impl.dart
│   ├── ocr/
│   │   ├── mlkit_ocr_engine.dart            # ML Kit実装
│   │   └── ocr_engine.dart                  # 抽象インターフェース
│   ├── parsers/
│   │   ├── parser_strategy.dart             # Strategy Interface
│   │   ├── table_vertical_parser.dart       # タイプA: 縦型表
│   │   ├── table_horizontal_parser.dart     # タイプB: 横型表
│   │   ├── freetext_parser.dart             # タイプC: フリーテキスト
│   │   ├── parser_factory.dart              # Factory: フォーマット自動判定
│   │   └── item_matcher.dart                # 検査項目名マッチング
│   └── security/
│       ├── app_lock_service.dart             # バイオメトリクス/PIN
│       └── encryption_service.dart           # DB暗号化キー管理
│
├── presentation/
│   ├── providers/
│   │   ├── dashboard_provider.dart
│   │   ├── checkup_list_provider.dart
│   │   ├── scan_provider.dart
│   │   ├── chart_provider.dart
│   │   ├── share_provider.dart
│   │   └── settings_provider.dart
│   ├── pages/
│   │   ├── lock_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── history_list_page.dart
│   │   ├── checkup_detail_page.dart
│   │   ├── chart_detail_page.dart
│   │   ├── scan_page.dart
│   │   ├── ocr_confirm_page.dart
│   │   ├── manual_input_page.dart
│   │   ├── share_page.dart
│   │   └── settings_page.dart
│   ├── widgets/
│   │   ├── summary_card.dart
│   │   ├── category_signal_badge.dart
│   │   ├── trend_line_chart.dart
│   │   ├── radar_chart_widget.dart
│   │   ├── heatmap_widget.dart
│   │   ├── result_table.dart
│   │   ├── confidence_indicator.dart
│   │   └── share_preview_dialog.dart
│   └── router/
│       └── app_router.dart                  # go_router設定
│
└── generated/                               # Riverpod / Isar コード生成出力
```

### 2.3 データフロー

```
[カメラ / ギャラリー]
        │
        ▼
[ImagePreprocessor]  ── クロップ、グレースケール、コントラスト強調
        │
        ▼
[OcrEngine (ML Kit)]  ── RecognizedText (生テキスト + BoundingBox)
        │
        ▼
[ParserFactory]  ── フォーマット自動判定
        │
        ├─ TableVerticalParser   (タイプA)
        ├─ TableHorizontalParser (タイプB)
        └─ FreetextParser        (タイプC)
              │
              ▼
[ItemMatcher]  ── TestItemMasterとのファジーマッチング
        │
        ▼
[ParsedCheckupResult]  ── 構造化データ + 信頼度スコア
        │
        ▼
[OcrConfirmPage]  ── ユーザー確認・修正
        │
        ▼
[CheckupRepository]  ── Isar永続化
        │
        ▼
[Dashboard / Charts]  ── fl_chart描画
```

---

## 3. ドメインモデル詳細設計

### 3.1 エンティティ定義

#### DE-01: Profile

```dart
class Profile {
  final String id;          // UUID v4
  final String name;
  final DateTime? birthDate;
  final Sex sex;            // enum: male, female, other, unspecified
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### DE-02: Checkup

```dart
class Checkup {
  final String id;           // UUID v4
  final String profileId;    // FK → Profile
  final DateTime date;       // 受診日
  final String? facilityName;
  final String? sourceImagePath;  // 元画像のローカルパス
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### DE-03: TestResult

```dart
class TestResult {
  final String id;
  final String checkupId;     // FK → Checkup
  final String itemCode;      // TestItemMaster.id への参照
  final String itemName;      // 表示用（OCR読み取り時の名称を保持）
  final double? value;        // 数値結果（定量）
  final String? valueText;    // テキスト結果（定性: 陽性/陰性 等）
  final String? unit;
  final double? refLow;       // 基準値下限
  final double? refHigh;      // 基準値上限
  final String? flag;         // H / L / A〜D 等
  final double confidence;    // OCR信頼度 0.0〜1.0
  final bool isManuallyEdited;
}
```

#### DE-04: TestCategory

```dart
class TestCategory {
  final String id;
  final String name;
  final int displayOrder;
  final String? iconName;  // アイコン識別子
}
```

#### DE-05: TestItemMaster

```dart
class TestItemMaster {
  final String id;           // 標準コード
  final String categoryId;   // FK → TestCategory
  final String standardName; // 正式名称
  final List<String> aliases; // 表記揺れ対応 (例: ["GOT", "AST", "AST(GOT)"])
  final String? unit;
  final double? defaultRefLow;
  final double? defaultRefHigh;
  final int displayOrder;
}
```

### 3.2 値オブジェクト

#### VO-01: TestValue

```dart
class TestValue {
  final double? numericValue;
  final String? textValue;
  final String? unit;

  bool get isQuantitative => numericValue != null;
  bool get isQualitative => textValue != null;
}
```

#### VO-02: ReferenceRange

```dart
class ReferenceRange {
  final double? low;
  final double? high;

  JudgmentFlag judge(double value) {
    if (low != null && value < low!) return JudgmentFlag.low;
    if (high != null && value > high!) return JudgmentFlag.high;
    return JudgmentFlag.normal;
  }
}
```

#### VO-03: ConfidenceScore

```dart
class ConfidenceScore {
  final double value;  // 0.0〜1.0

  ConfidenceLevel get level {
    if (value >= 0.9) return ConfidenceLevel.high;
    if (value >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  bool get needsUserConfirmation => value < 0.7;
}
```

---

## 4. OCR・パーサー設計

### 4.1 画像前処理パイプライン

```
入力画像
  ├─ (1) エッジ検出・自動クロッピング
  │     └─ 四角形検出でドキュメント領域を特定
  ├─ (2) 遠近補正
  │     └─ 斜め撮影時の台形歪みを補正
  ├─ (3) グレースケール変換
  ├─ (4) コントラスト強調 (CLAHE相当)
  ├─ (5) 二値化 (Otsu's method)
  │     └─ OCR精度向上のための最終段
  └─ (6) リサイズ
        └─ ML Kit推奨の入力解像度に調整
```

### 4.2 パーサーアーキテクチャ

#### Strategy Pattern + Factory

```dart
// Strategy Interface
abstract class CheckupParser {
  /// パース可能かどうかの判定（0.0〜1.0のスコア）
  double canParse(RecognizedText text);

  /// パース実行
  ParsedCheckupResult parse(RecognizedText text);
}

// Factory
class ParserFactory {
  final List<CheckupParser> _parsers = [
    TableVerticalParser(),
    TableHorizontalParser(),
    FreetextParser(),  // 最終フォールバック
  ];

  CheckupParser selectParser(RecognizedText text) {
    final scored = _parsers
        .map((p) => (parser: p, score: p.canParse(text)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.first.parser;
  }
}
```

#### パースフロー詳細

```
RecognizedText
    │
    ▼
(1) TextBlock → 行(TextLine)に分解
    │
    ▼
(2) 行のBoundingBoxでグリッド構造を推定
    │  ├─ X座標のクラスタリング → 列検出
    │  └─ Y座標のクラスタリング → 行検出
    │
    ▼
(3) セル内テキストの分類
    │  ├─ 数値パターン: /^\d+\.?\d*$/
    │  ├─ 範囲パターン: /(\d+\.?\d*)\s*[〜~\-]\s*(\d+\.?\d*)/
    │  ├─ 単位パターン: /(mg\/dL|g\/dL|%|mmHg|U\/L|...)/
    │  └─ 判定パターン: /^[A-D]$|^[HL]$/
    │
    ▼
(4) ItemMatcherで検査項目名をマスタと照合
    │  ├─ 完全一致
    │  ├─ エイリアス一致
    │  └─ ファジーマッチ (Levenshtein距離 + Jaccard係数)
    │
    ▼
(5) ParsedCheckupResult を生成
    └─ 各フィールドにConfidenceScoreを付与
```

### 4.3 ItemMatcher 設計

```dart
class ItemMatcher {
  final List<TestItemMaster> _masters;

  MatchResult? match(String ocrText) {
    // Phase 1: 完全一致
    final exact = _masters.firstWhereOrNull(
      (m) => m.standardName == ocrText || m.aliases.contains(ocrText),
    );
    if (exact != null) return MatchResult(item: exact, confidence: 1.0);

    // Phase 2: 正規化後一致（全角→半角、スペース除去）
    final normalized = _normalize(ocrText);
    final normMatch = _masters.firstWhereOrNull(
      (m) => _normalize(m.standardName) == normalized ||
             m.aliases.any((a) => _normalize(a) == normalized),
    );
    if (normMatch != null) return MatchResult(item: normMatch, confidence: 0.95);

    // Phase 3: ファジーマッチ
    final fuzzy = _masters
        .map((m) => (item: m, score: _fuzzyScore(normalized, m)))
        .where((e) => e.score > 0.6)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (fuzzy.isNotEmpty) {
      return MatchResult(item: fuzzy.first.item, confidence: fuzzy.first.score);
    }
    return null; // マッチ失敗 → ユーザーに手動マッピングを促す
  }
}
```

---

## 5. 可視化設計

### 5.1 ダッシュボード構成

```
┌─────────────────────────────────────┐
│  プロフィール名  │  最終受診: 2025/10/15  │
├─────────────────────────────────────┤
│  [サマリーカード]                         │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │ 血圧 │ │ 脂質 │ │ 糖代謝│ │ 肝機能│  │
│  │  🟢  │ │  🟡  │ │  🟢  │ │  🔴  │  │
│  │ 正常 │ │ 注意 │ │ 正常 │ │ 異常 │  │
│  └─────┘ └─────┘ └─────┘ └─────┘  │
├─────────────────────────────────────┤
│  [注目項目] 前回からの変化                 │
│  γ-GTP: 85 U/L  ↑ (+23)  ⚠️       │
│  LDL-C: 142 mg/dL  ↓ (-8)          │
│  HbA1c: 5.6%  → (±0)               │
├─────────────────────────────────────┤
│  [クイックチャート] LDL-C 推移            │
│  ~~~~~~~~ mini折れ線 ~~~~~~~~         │
└─────────────────────────────────────┘
```

### 5.2 チャート設計パターン

#### 時系列折れ線グラフ

```
値
 ^
 |        ┌──────────────────┐ 基準上限
 |  *     │  正常範囲 (帯表示)  │
 |   \  * │                    │
 |    \/  │                    │
 |     \  └──────────────────┘ 基準下限
 |      *
 +──────────────────────────> 時間
   2021  2022  2023  2024  2025
```

設計ポイント:
- 基準範囲を半透明バンドで背景描画
- 異常値のデータポイントを赤で強調
- タップでツールチップ（日付・値・前回差）表示
- ピンチズームで期間拡大/縮小

#### レーダーチャート

```
        血圧
         │
    腎機能───┤───血液一般
         │
    肝機能───┤───脂質
         │
        糖代謝
```

設計ポイント:
- 各軸は0〜100のスコアに正規化
- 正規化式: score = (基準範囲中央からの偏差) をスケール変換
- 基準範囲内を100、逸脱度に応じて減点

### 5.3 信号色アルゴリズム

```dart
enum SignalLevel { normal, caution, abnormal }

SignalLevel calculateCategorySignal(List<TestResult> results) {
  final flags = results
      .where((r) => r.value != null)
      .map((r) {
        final range = ReferenceRange(low: r.refLow, high: r.refHigh);
        return range.judge(r.value!);
      })
      .toList();

  if (flags.any((f) => f == JudgmentFlag.high || f == JudgmentFlag.low)) {
    return SignalLevel.abnormal;
  }
  // 境界付近（基準値の±10%以内）があれば注意
  final borderline = results.where((r) => _isNearBoundary(r)).toList();
  if (borderline.isNotEmpty) return SignalLevel.caution;
  return SignalLevel.normal;
}
```

---

## 6. 共有機能設計

### 6.1 共有フロー

```
[共有ボタンタップ]
      │
      ▼
[共有設定画面]
  ├─ 共有形式選択: PDF / チャート画像 / JSON / CSV
  ├─ 対象期間選択: 最新1回 / 直近3回 / カスタム期間
  ├─ 項目選択: 全項目 / カテゴリ選択 / 個別選択
  └─ プライバシー設定:
      ├─ □ 氏名を含める
      ├─ □ 生年月日を含める
      └─ □ 受診機関名を含める
      │
      ▼
[プレビュー画面]
  └─ 生成されたPDF/画像のプレビュー表示
      │
      ▼
[確認ダイアログ]
  「以下のデータを共有します。よろしいですか？」
  - 対象: 2025年度健診 (全12項目)
  - 個人情報: 氏名あり、生年月日なし
  [キャンセル] [共有する]
      │
      ▼
[OS Share Sheet]
  └─ LINE / メール / AirDrop / ファイル保存 等
      │
      ▼
[共有ログ保存]
  └─ 日時、形式、項目数をローカルに記録
```

### 6.2 PDFレポートレイアウト

```
┌──────────────────────────────────┐
│  KenViz 健康診断レポート              │
│  氏名: ○○ ○○  受診日: 2025/10/15  │
├──────────────────────────────────┤
│  [カテゴリ別結果テーブル]              │
│  項目名     │ 今回 │ 前回 │ 基準値  │
│  ──────────┼────┼────┼─────│
│  LDL-C     │ 142  │ 150  │ 70-139 │
│  ...       │      │      │        │
├──────────────────────────────────┤
│  [主要項目の推移チャート]             │
│  ~~~~ 折れ線グラフ (PNG埋め込み) ~~~~ │
├──────────────────────────────────┤
│  生成日: 2026-03-11                │
│  KenViz v1.0 にて生成              │
└──────────────────────────────────┘
```

### 6.3 JSON エクスポートスキーマ

```json
{
  "version": "1.0",
  "exportedAt": "2026-03-11T12:00:00+09:00",
  "profile": {
    "name": "山田 太郎",
    "birthDate": "1985-05-15",
    "sex": "male"
  },
  "checkups": [
    {
      "id": "uuid-1",
      "date": "2025-10-15",
      "facilityName": "○○クリニック",
      "results": [
        {
          "itemCode": "LDL_C",
          "itemName": "LDL-コレステロール",
          "value": 142.0,
          "unit": "mg/dL",
          "refLow": 70.0,
          "refHigh": 139.0,
          "flag": "H"
        }
      ]
    }
  ]
}
```

---

## 7. セキュリティ設計

### 7.1 アプリロック

```
[アプリ起動 / バックグラウンド復帰]
      │
      ▼
[ロック状態チェック]
  ├─ ロック無効 → ダッシュボードへ
  └─ ロック有効
      │
      ▼
[認証方式判定]
  ├─ バイオメトリクス有効 → local_auth呼び出し
  │   ├─ 成功 → ダッシュボードへ
  │   └─ 失敗 → PINフォールバック
  └─ PINのみ → PIN入力画面
      ├─ 成功 → ダッシュボードへ
      └─ 5回失敗 → 30秒ロックアウト
```

### 7.2 データ暗号化戦略

| レイヤー | 方式 | 備考 |
|---|---|---|
| DB暗号化 | Isar暗号化オプション or SQLCipher (sqflite移行時) | マスターキーで暗号化 |
| キー管理 | flutter_secure_storage | iOS Keychain / Android Keystore |
| 画像ファイル | アプリサンドボックス内保存 | OS標準の保護に依存 |
| エクスポートファイル | 平文（ユーザー明示操作のため） | 将来的にパスワード付きZIP検討 |

### 7.3 ネットワーク遮断

```dart
// main.dart にて
// HTTP通信を完全に無効化（ML Kitモデル以外）
class NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw UnsupportedError('Network access is disabled in this app');
  }
}

// ※ ML Kitモデルの初回DLのみ例外として許可する設計を別途検討
```

---

## 8. テスト戦略

### 8.1 テストピラミッド

| テストレベル | 対象 | ツール | カバレッジ目標 |
|---|---|---|---|
| 単体テスト | Domain / Application / Parser | flutter_test | 90%以上 |
| Widgetテスト | 個別Widget・Page | flutter_test + mockito | 主要画面80%以上 |
| 統合テスト | OCR→パース→保存の一連フロー | integration_test | 主要フロー100% |
| ゴールデンテスト | チャートWidgetのスナップショット | flutter_test (golden) | 全チャート種別 |

### 8.2 OCRパーサーテスト

```
test/fixtures/
├── type_a/           # タイプA: 縦型表
│   ├── sample_01.png
│   ├── sample_01_expected.json
│   ├── sample_02.png
│   └── sample_02_expected.json
├── type_b/           # タイプB: 横型表
└── type_c/           # タイプC: フリーテキスト
```

テスト戦略:
- 実際の健診結果画像を匿名化してテストフィクスチャに使用
- 各フォーマットにつき最低10件のテストケース
- OCR精度の回帰テストを自動化
- パーサー単体テストはRecognizedTextのモックで実行

### 8.3 重点テスト項目

| テスト項目 | 確認観点 |
|---|---|
| 数値精度 | 小数点以下の正確な読み取り (HbA1c: 5.6% 等) |
| 表記揺れ | "γ-GTP" / "γGTP" / "ガンマGTP" の統一マッチ |
| 基準範囲解析 | "70〜139" / "70-139" / "70 ~ 139" の正しいパース |
| 境界値 | 基準値ちょうどの場合の判定 |
| 空欄処理 | 未実施項目の欠損値ハンドリング |
| 画像品質 | ブレ・影・斜め撮影への耐性 |

---

## 9. 初期データ・マスタ設計

### 9.1 検査項目マスタ (初期投入)

アプリ初回起動時にassets/master_data.jsonからロードする。

主要項目（抜粋）:

| standardName | aliases | unit | defaultRefLow | defaultRefHigh | category |
|---|---|---|---|---|---|
| 身長 | ["身長"] | cm | - | - | 身体計測 |
| 体重 | ["体重"] | kg | - | - | 身体計測 |
| BMI | ["BMI", "体格指数"] | - | 18.5 | 24.9 | 身体計測 |
| 収縮期血圧 | ["最高血圧", "血圧(上)"] | mmHg | - | 129 | 血圧 |
| 拡張期血圧 | ["最低血圧", "血圧(下)"] | mmHg | - | 84 | 血圧 |
| LDL-コレステロール | ["LDL-C", "LDLコレステロール", "悪玉コレステロール"] | mg/dL | 70 | 139 | 脂質 |
| HDL-コレステロール | ["HDL-C", "HDLコレステロール", "善玉コレステロール"] | mg/dL | 40 | - | 脂質 |
| 中性脂肪 | ["TG", "トリグリセリド"] | mg/dL | 30 | 149 | 脂質 |
| 空腹時血糖 | ["FPG", "血糖(空腹時)", "グルコース"] | mg/dL | 70 | 99 | 糖代謝 |
| HbA1c | ["HbA1c(NGSP)", "ヘモグロビンA1c"] | % | 4.6 | 5.9 | 糖代謝 |
| AST | ["AST(GOT)", "GOT"] | U/L | 10 | 30 | 肝機能 |
| ALT | ["ALT(GPT)", "GPT"] | U/L | 6 | 30 | 肝機能 |
| γ-GTP | ["γGTP", "ガンマGTP", "γ-GT"] | U/L | - | 50 | 肝機能 |
| クレアチニン | ["Cr", "CRE"] | mg/dL | 0.6 | 1.1 | 腎機能 |
| eGFR | ["推算GFR"] | mL/min/1.73m² | 60 | - | 腎機能 |
| 尿酸 | ["UA"] | mg/dL | 2.1 | 7.0 | 腎機能 |

基準値は「特定健康診査」の基準を初期値とし、ユーザーが個別に上書き可能な設計とする。性別・年齢による基準値差は将来対応。

---

## 10. 開発環境・CI

### 10.1 開発環境

| ツール | バージョン |
|---|---|
| Flutter | 3.x (stable) |
| Dart | 3.x |
| IDE | VS Code + Flutter/Dart Extensions |
| コード生成 | build_runner + riverpod_generator + isar_generator |
| Lint | flutter_lints (strict mode) |
| フォーマット | dart format (CI必須) |

### 10.2 CI パイプライン

```
push / PR
  ├─ dart format --set-exit-if-changed
  ├─ dart analyze
  ├─ flutter test (単体 + Widget)
  ├─ flutter test --coverage
  │   └─ カバレッジ閾値チェック
  └─ build (iOS / Android) ※ main branch のみ
```

---

## 改訂履歴

| バージョン | 日付 | 内容 | 担当 |
|---|---|---|---|
| 1.0 | 2026-03-11 | 初版作成 | Yuji |
