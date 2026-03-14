# KenViz - 健診結果 OCR ビューア

完全オンデバイスで動作する健康診断結果のOCR読み取り・可視化アプリ。

## 特徴

- 外部通信なし: OCR処理・データ保存・可視化の全てが端末内で完結
- カメラ撮影 or ギャラリー選択で健診結果をスキャン
- 時系列チャートで健康推移を可視化
- PDF/画像でのレポート共有機能

## セットアップ

```bash
# fvm + Flutter のセットアップ
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## 開発コマンド (PDCA サイクル)

```bash
make help       # コマンド一覧
make check      # format → analyze → test
make spiral     # codegen → check → build (1サイクル)
make watch      # ファイル変更監視でコード自動生成
make coverage   # カバレッジレポート
```

## ドキュメント

- [要件仕様書](docs/01_requirements.md)
- [設計書](docs/02_design.md)
- [トレーサビリティマトリクス](docs/03_traceability.md)

## 技術スタック

| レイヤー | 技術 |
|---|---|
| UI | Flutter 3.41.x |
| 状態管理 | Riverpod 3.x |
| OCR | google_mlkit_text_recognition |
| ローカルDB | Isar 3.x |
| チャート | fl_chart |

## ディレクトリ構成

```
lib/
├── core/          # 共通ユーティリティ、定数、テーマ
├── domain/        # エンティティ、値オブジェクト、リポジトリIF
├── application/   # ユースケース、サービス
├── infrastructure/ # DB実装、OCR、パーサー、セキュリティ
└── presentation/  # 画面、Widget、プロバイダー
```
