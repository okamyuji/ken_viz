.PHONY: help setup fmt lint analyze test build check codegen watch clean spiral

FLUTTER := fvm flutter
DART := fvm dart

# ─────────────────────────────────────────────
#  PDCA スパイラル開発サイクル
#  Plan → Do → Check → Act
# ─────────────────────────────────────────────

help: ## ヘルプ表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

setup: ## 初期セットアップ (fvm install, pub get, codegen)
	@bash scripts/setup.sh

# ── Plan ──

codegen: ## コード生成 (Riverpod, Freezed, Isar, JSON)
	@echo "🔧 [Plan] コード生成..."
	$(DART) run build_runner build --delete-conflicting-outputs

watch: ## コード生成 (ファイル変更監視モード)
	@echo "👁  [Plan] ファイル変更監視中..."
	$(DART) run build_runner watch --delete-conflicting-outputs

# ── Do ──

fmt: ## コードフォーマット修正
	@echo "✨ [Do] コードフォーマット..."
	$(DART) format lib/ test/

# ── Check ──

lint: ## フォーマットチェック (差分検出のみ)
	@echo "📝 [Check] フォーマットチェック..."
	$(DART) format --set-exit-if-changed lib/ test/

analyze: ## 静的解析
	@echo "🔍 [Check] 静的解析..."
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

test: ## テスト実行
	@echo "🧪 [Check] テスト実行..."
	$(FLUTTER) test --coverage

test-unit: ## 単体テストのみ
	@echo "🧪 [Check] 単体テスト..."
	$(FLUTTER) test test/domain/ test/application/ test/infrastructure/

test-widget: ## Widgetテストのみ
	@echo "🧪 [Check] Widgetテスト..."
	$(FLUTTER) test test/presentation/

build-android: ## Android APKビルド
	@echo "📦 [Check] Android ビルド..."
	$(FLUTTER) build apk --debug

build-ios: ## iOS ビルド (macOSのみ)
	@echo "📦 [Check] iOS ビルド..."
	$(FLUTTER) build ios --debug --no-codesign

# ── Act ──

check: fmt analyze test ## PDCA Check 一括実行 (format → analyze → test)
	@echo ""
	@echo "✅ 全チェック通過"

spiral: codegen check build-android ## スパイラル開発 1サイクル (codegen → check → build)
	@echo ""
	@echo "🔄 スパイラル 1サイクル完了"
	@echo "   - コード生成: OK"
	@echo "   - フォーマット: OK"
	@echo "   - 静的解析: OK"
	@echo "   - テスト: OK"
	@echo "   - ビルド: OK"

# ── Utilities ──

clean: ## ビルド成果物のクリーン
	@echo "🧹 クリーン..."
	$(FLUTTER) clean
	rm -rf .dart_tool/ build/ coverage/

coverage: test ## カバレッジレポート生成
	@echo "📊 カバレッジレポート..."
	@which genhtml >/dev/null 2>&1 && \
		genhtml coverage/lcov.info -o coverage/html && \
		echo "  coverage/html/index.html を開いてください" || \
		echo "  genhtml が未インストール: sudo apt install lcov"

deps-check: ## 依存関係の更新チェック
	@echo "📋 依存関係チェック..."
	$(FLUTTER) pub outdated

deps-upgrade: ## 依存関係のアップグレード
	@echo "⬆️  依存関係アップグレード..."
	$(FLUTTER) pub upgrade --major-versions
