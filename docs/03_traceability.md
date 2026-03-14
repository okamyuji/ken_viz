# KenViz 要件・設計トレーサビリティマトリクス

> **Version:** 1.0
> **Date:** 2026-03-11
> **Status:** Draft
> **Author:** Yuji
> **参照ドキュメント:**
> - 01_requirements.md (要件仕様書 v1.0)
> - 02_design.md (設計書 v1.0)

---

## 1. 本ドキュメントの目的

要件仕様書の各ユースケース・非機能要件が、設計書のどのコンポーネント・モジュール・テストによってカバーされているかを追跡可能にする。未カバーの要件がないことを保証し、設計変更時の影響範囲を明確にする。

---

## 2. ユースケース → 設計要素 マッピング

| UC ID | ユースケース | 設計モジュール | UseCase クラス | 画面 | テスト区分 |
|---|---|---|---|---|---|
| UC-01 | 健診結果をカメラで撮影しOCR読み取り | OcrEngine, ImagePreprocessor, ParserFactory, ParserStrategy各実装, ItemMatcher | ScanCheckupUsecase | ScanPage | 単体(Parser), 統合(OCR→Parse→保存) |
| UC-02 | OCR結果を確認・手動修正 | ParsedCheckupResult, ConfidenceScore | ConfirmOcrResultUsecase | OcrConfirmPage | Widget, 統合 |
| UC-03 | 手動で検査項目を入力 | TestItemMaster, CheckupRepository | ManualInputUsecase | ManualInputPage | Widget, 単体 |
| UC-04 | ダッシュボードで最新結果を一覧表示 | CheckupRepository, SignalLevel算出 | GetDashboardUsecase | DashboardPage | Widget, ゴールデン |
| UC-05 | 特定項目の時系列推移グラフ | CheckupRepository, fl_chart | GetTrendChartUsecase | ChartDetailPage | Widget, ゴールデン |
| UC-06 | 基準値との比較で異常値ハイライト | ReferenceRange, JudgmentFlag, CategorySignal算出 | GetTrendChartUsecase | DashboardPage, ChartDetailPage | 単体(ReferenceRange) |
| UC-07 | 結果をPDFエクスポート | PdfGeneratorService | ExportPdfUsecase | SharePage | 統合 |
| UC-08 | チャートのスクリーンショット共有 | share_plus, RepaintBoundary | ShareChartUsecase | ChartDetailPage → SharePage | 統合 |
| UC-09 | JSON エクスポート/インポート | LocalFileDatasource, JSONスキーマ | ExportImportJsonUsecase | SettingsPage | 単体(シリアライズ), 統合 |
| UC-10 | アプリロック設定 | AppLockService, local_auth | - (Settings内) | LockPage, SettingsPage | Widget, 統合 |
| UC-11 | 複数プロフィールで家族データ管理 | Profile, ProfileRepository | ManageProfileUsecase | SettingsPage | 単体, Widget |
| UC-12 | ギャラリーから既存画像を読み込み | image_picker, ImagePreprocessor | ScanCheckupUsecase | ScanPage | 統合 |

---

## 3. 非機能要件 → 設計要素 マッピング

### 3.1 プライバシー・セキュリティ

| 要件ID | 要件 | 設計要素 | 設計書セクション | 検証方法 |
|---|---|---|---|---|
| NFR-SEC-01 | 完全ローカル処理 | 全レイヤーがオンデバイス、ネットワークレイヤー不在 | §2.1 レイヤーアーキテクチャ | アーキテクチャレビュー、通信ログ確認 |
| NFR-SEC-02 | ネットワーク通信禁止 | NoNetworkHttpOverrides | §7.3 ネットワーク遮断 | 統合テスト(HTTP呼出で例外確認) |
| NFR-SEC-03 | アプリロック | AppLockService, local_auth | §7.1 アプリロック | 統合テスト(認証フロー) |
| NFR-SEC-04 | データ暗号化 | EncryptionService, flutter_secure_storage | §7.2 データ暗号化戦略 | 単体テスト(暗号化/復号) |
| NFR-SEC-05 | アナリティクス禁止 | 外部SDKを一切含めない設計方針 | §1.1 アーキテクチャ原則 | 依存関係レビュー(pubspec.yaml) |

### 3.2 パフォーマンス

| 要件ID | 要件 | 設計要素 | 検証方法 |
|---|---|---|---|
| NFR-PERF-01 | OCR処理 3秒以内/ページ | ImagePreprocessor最適化, ML Kit on-device | ベンチマークテスト(実機5端末以上) |
| NFR-PERF-02 | アプリ起動 2秒以内 | 遅延初期化, マスターデータキャッシュ | 実機計測(コールドスタート) |
| NFR-PERF-03 | チャート描画 60fps | fl_chart, RepaintBoundaryの適切な配置 | Flutter DevTools Performanceプロファイル |
| NFR-PERF-04 | DBクエリ 100ms以内 | Isarインデックス設計 (checkupId, itemCode, date) | ベンチマークテスト(5000レコード) |
| NFR-PERF-05 | アプリサイズ 50MB以内 | ML Kitモデル最適化, アセット圧縮 | ビルド成果物サイズ計測 |

### 3.3 対応プラットフォーム

| 要件ID | 要件 | 設計要素 | 検証方法 |
|---|---|---|---|
| NFR-PLAT-01 | iOS 16.0+ | Flutter iOS最小デプロイターゲット設定 | CI ビルド + 実機テスト |
| NFR-PLAT-02 | Android API 26+ | minSdkVersion 26 | CI ビルド + エミュレータテスト |

### 3.4 アクセシビリティ

| 要件ID | 要件 | 設計要素 | 検証方法 |
|---|---|---|---|
| NFR-A11Y-01 | ダイナミックタイプ | MediaQuery.textScaleFactor対応 | Widgetテスト(scale 1.0/1.5/2.0) |
| NFR-A11Y-02 | ダークモード | AppTheme (Light/Dark) | ゴールデンテスト(両テーマ) |
| NFR-A11Y-03 | VoiceOver/TalkBack | Semanticsラベル付与 | 手動テスト + accessibility_scanner |
| NFR-A11Y-04 | 色覚異常対応 | 信号色にアイコン/パターン併用 | 色覚シミュレータで目視確認 |

---

## 4. ドメインエンティティ → 設計要素 マッピング

| エンティティ | 設計ID | Dartクラス | Isarスキーマ | 関連UseCase |
|---|---|---|---|---|
| Profile | DE-01 | domain/entities/profile.dart | isar/schemas/ | UC-11, UC-04 |
| Checkup | DE-02 | domain/entities/checkup.dart | isar/schemas/ | UC-01, UC-04, UC-05, UC-07 |
| TestResult | DE-03 | domain/entities/test_result.dart | isar/schemas/ | UC-01〜UC-09 |
| TestCategory | DE-04 | domain/entities/test_category.dart | isar/schemas/ | UC-04, UC-05 |
| TestItemMaster | DE-05 | domain/entities/test_item_master.dart | isar/schemas/ | UC-01〜UC-03 |

---

## 5. 共有機能 → 設計要素 マッピング

| 共有手段 | 優先度 | 設計モジュール | 設計書セクション | プライバシー保護要素 |
|---|---|---|---|---|
| PDFレポート | Must | PdfGeneratorService, ExportPdfUsecase | §6.2 PDFレポートレイアウト | 確認ダイアログ, 項目選択, 個人情報除外オプション |
| チャート画像 | Must | RepaintBoundary → share_plus, ShareChartUsecase | §6.1 共有フロー | 確認ダイアログ |
| JSONエクスポート | Should | LocalFileDatasource, ExportImportJsonUsecase | §6.3 JSONエクスポートスキーマ | 確認ダイアログ, 項目選択 |
| CSVエクスポート | Could | (Phase 5で設計) | - | 確認ダイアログ |

---

## 6. テストカバレッジマトリクス

### 6.1 テストレベル別カバレッジ

| コンポーネント | 単体テスト | Widgetテスト | 統合テスト | ゴールデンテスト |
|---|---|---|---|---|
| Domain Entities | ✅ | - | - | - |
| Value Objects (ReferenceRange等) | ✅ | - | - | - |
| Parsers (TypeA/B/C) | ✅ | - | ✅ | - |
| ItemMatcher | ✅ | - | - | - |
| UseCases | ✅ | - | - | - |
| Repository実装 | ✅ | - | ✅ | - |
| DashboardPage | - | ✅ | - | ✅ |
| ChartDetailPage | - | ✅ | - | ✅ |
| OcrConfirmPage | - | ✅ | ✅ | - |
| ScanPage | - | ✅ | ✅ | - |
| SharePage | - | ✅ | ✅ | - |
| LockPage | - | ✅ | ✅ | - |
| OCR→Parse→保存フロー | - | - | ✅ | - |
| 共有→PDF生成フロー | - | - | ✅ | - |
| アプリロックフロー | - | - | ✅ | - |

### 6.2 OCRパーサー精度テスト

| テスト区分 | テストケース数(目標) | 合格基準 |
|---|---|---|
| タイプA (縦型表) | 15件以上 | 数値フィールド正答率 90%以上 |
| タイプB (横型表) | 10件以上 | 数値フィールド正答率 90%以上 |
| タイプC (フリーテキスト) | 10件以上 | 数値フィールド正答率 85%以上 |
| 項目名マッチング | 全マスタ項目×3変形 | マッチ成功率 95%以上 |
| 基準範囲パース | 20パターン以上 | 正答率 95%以上 |
| 低品質画像 | 10件以上 | 信頼度スコアが0.7未満を正しく検出 |

---

## 7. フェーズ別実装トレーサビリティ

| フェーズ | UC カバレッジ | NFR カバレッジ | 主要成果物 |
|---|---|---|---|
| Phase 0: 基盤 | - | NFR-PLAT-01, 02 | プロジェクト構成, DBスキーマ, マスターデータ, CI設定 |
| Phase 1: コア | UC-01, 02, 03, 12 | NFR-SEC-01, 02, NFR-PERF-01 | OCRエンジン, パーサー(TypeA), 確認UI, DB保存 |
| Phase 2: 可視化 | UC-04, 05, 06 | NFR-PERF-03, 04, NFR-A11Y-01, 02 | ダッシュボード, チャート, 信号色, ダークモード |
| Phase 3: 共有 | UC-07, 08, 09 | - | PDF生成, 画像共有, JSONエクスポート, 共有フロー |
| Phase 4: セキュリティ | UC-10 | NFR-SEC-03, 04, 05 | アプリロック, DB暗号化, 共有プライバシー制御 |
| Phase 5: 拡張 | UC-11 | NFR-A11Y-03, 04 | TypeB/Cパーサー, 複数プロフィール, アクセシビリティ強化 |

---

## 8. 未カバー分析

### 8.1 現時点での未カバー項目

| 項目 | 状態 | 対応方針 |
|---|---|---|
| CSVエクスポート (Could) | 設計未着手 | Phase 5以降で設計追加 |
| 性別・年齢別基準値 | マスターデータに構造はあるが初期データ未整備 | Phase 5でマスターデータ拡充 |
| Isarのスキーママイグレーション戦略 | 方針未決定 | Phase 0で詳細設計 |
| ML Kitモデル初回DLの例外的ネットワーク許可 | NoNetworkHttpOverridesとの整合性未解決 | Phase 1で設計 |

### 8.2 リスク要件との対応

| リスク | 要件 | 設計上の対策 | 対策の充分性 |
|---|---|---|---|
| OCR精度不足 | UC-02 | ConfidenceScore + OcrConfirmPage | ✅ 充分（ユーザー修正で100%カバー） |
| 表記揺れ | UC-01 | ItemMatcher (3段階マッチ) | ✅ 充分（ファジーマッチ + 手動マッピング） |
| 想定外フォーマット | UC-03 | ManualInputPage (フォールバック) | ✅ 充分（手動入力で100%カバー） |
| ML Kit精度限界 | UC-01 | ImagePreprocessor (6段パイプライン) | ⚠️ 要検証（実機テストで確認） |
| パフォーマンス低下 | NFR-PERF-04 | Isarインデックス設計 | ⚠️ 要検証（5000レコードベンチマーク） |

---

## 9. 変更管理ルール

### 9.1 トレーサビリティ維持手順

要件または設計の変更時は、以下の手順で本ドキュメントを更新する:

1. 変更対象のUC-IDまたはNFR-IDを特定
2. 本マトリクスで影響を受ける設計要素・テストを特定
3. 設計書の該当セクションを更新
4. 本マトリクスの対応行を更新し、変更履歴に記録
5. 影響を受けるテストケースを更新・追加

### 9.2 レビューチェックリスト

- [ ] 全てのMust UCが設計要素にマッピングされているか
- [ ] 全てのNFRが検証方法を持つか
- [ ] 各フェーズの完了条件が明確か
- [ ] 未カバー項目に対応方針があるか
- [ ] テストカバレッジに空白がないか

---

## 改訂履歴

| バージョン | 日付 | 内容 | 担当 |
|---|---|---|---|
| 1.0 | 2026-03-11 | 初版作成 | Yuji |
