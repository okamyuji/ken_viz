#!/usr/bin/env bash
# KenViz 初期セットアップスクリプト
# Usage: ./scripts/setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=========================================="
echo "  KenViz - 初期セットアップ"
echo "=========================================="

# --- fvm ---
echo ""
echo "[1/6] fvm チェック..."
if ! command -v fvm &>/dev/null; then
  echo "  fvm をインストール中..."
  dart pub global activate fvm
fi

echo "  fvm install..."
fvm install
fvm use --force

echo "  Flutter バージョン:"
fvm flutter --version

# --- 依存関係 ---
echo ""
echo "[2/6] 依存関係を取得中..."
fvm flutter pub get

# --- コード生成 ---
echo ""
echo "[3/6] コード生成を実行中..."
fvm dart run build_runner build --delete-conflicting-outputs

# --- 解析 ---
echo ""
echo "[4/6] 静的解析を実行中..."
fvm flutter analyze --no-fatal-infos || true

# --- フォーマット ---
echo ""
echo "[5/6] コードフォーマットチェック..."
fvm dart format --set-exit-if-changed lib/ test/ || {
  echo "  ⚠️  フォーマットが必要なファイルがあります。'make fmt' で修正してください"
}

# --- テスト ---
echo ""
echo "[6/6] テストを実行中..."
fvm flutter test || {
  echo "  ⚠️  テストが一部失敗しました。詳細を確認してください"
}

echo ""
echo "=========================================="
echo "  セットアップ完了"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "  make check    # PDCA: analyze → test → build"
echo "  make watch    # ファイル変更監視で自動コード生成"
echo "  make spiral   # スパイラル開発サイクル実行"
