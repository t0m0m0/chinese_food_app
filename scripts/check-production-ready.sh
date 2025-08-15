#!/bin/bash

# 本番環境準備チェックスクリプト
# check-production-ready.sh
# 
# 本番リリース前の総合チェックを実行します

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# チェック結果カウンター
PASSED=0
FAILED=0
WARNINGS=0

# チェック結果を記録する関数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              本番環境準備チェックスクリプト                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}🔍 本番リリース前の総合チェックを開始します...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. 開発環境チェック
echo -e "\n${BLUE}📦 1. 開発環境チェック${NC}"

# Flutter環境
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    check_pass "Flutter環境: $FLUTTER_VERSION"
else
    check_fail "Flutter SDKが見つかりません"
fi

# Dart環境
if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version | cut -d' ' -f4)
    check_pass "Dart環境: $DART_VERSION"
else
    check_fail "Dart SDKが見つかりません"
fi

# 2. プロジェクト構成チェック
echo -e "\n${BLUE}📁 2. プロジェクト構成チェック${NC}"

# 必須ファイルの存在確認
required_files=(
    "pubspec.yaml"
    "lib/main.dart"
    "config/production.yaml"
    "config/staging.yaml"
    "scripts/deploy-production.sh"
    "scripts/setup-production-keys.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        check_pass "必須ファイル存在: $file"
    else
        check_fail "必須ファイル不足: $file"
    fi
done

# .gitignore チェック
if grep -q "\.env" .gitignore && grep -q "CLAUDE\.md" .gitignore; then
    check_pass ".gitignore設定: 機密情報が適切に除外されています"
else
    check_warn ".gitignore設定: 機密情報の除外設定を確認してください"
fi

# 3. コード品質チェック
echo -e "\n${BLUE}🔍 3. コード品質チェック${NC}"

# フォーマットチェック
if dart format --set-exit-if-changed . &> /dev/null; then
    check_pass "コードフォーマット: 適切にフォーマットされています"
else
    check_fail "コードフォーマット: dart format . を実行してください"
fi

# 静的解析
if flutter analyze &> /dev/null; then
    check_pass "静的解析: エラーなし"
else
    check_fail "静的解析: 修正が必要なエラーがあります"
fi

# 4. テストチェック
echo -e "\n${BLUE}🧪 4. テストチェック${NC}"

# テスト実行
TEST_OUTPUT=$(flutter test 2>&1)
if echo "$TEST_OUTPUT" | grep -q "All tests passed"; then
    TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -o '[0-9]\+ tests' | head -1)
    check_pass "全テスト合格: $TEST_COUNT"
else
    check_fail "テスト失敗: 修正が必要です"
fi

# テストカバレッジチェック（実行可能な場合）
if flutter test --coverage &> /dev/null; then
    if [ -f "coverage/lcov.info" ]; then
        check_pass "テストカバレッジ: 生成済み"
    else
        check_warn "テストカバレッジ: 生成に失敗"
    fi
fi

# 5. セキュリティチェック
echo -e "\n${BLUE}🔒 5. セキュリティチェック${NC}"

# APIキーハードコーディングチェック
if grep -r "YOUR_API_KEY_HERE" lib/ &> /dev/null; then
    check_fail "セキュリティ: プレースホルダーAPIキーが残っています"
else
    check_pass "セキュリティ: プレースホルダーAPIキーなし"
fi

# パスワードやトークンの検出
if grep -ri -E "(password|token|secret|key)\s*[:=]\s*['\"][^'\"]{8,}" lib/ &> /dev/null; then
    check_warn "セキュリティ: 機密情報がハードコーディングされている可能性があります"
else
    check_pass "セキュリティ: 機密情報のハードコーディングなし"
fi

# 6. 依存関係チェック
echo -e "\n${BLUE}📦 6. 依存関係チェック${NC}"

# pubspec.lock の存在
if [ -f "pubspec.lock" ]; then
    check_pass "依存関係: pubspec.lock 存在"
else
    check_fail "依存関係: flutter pub get を実行してください"
fi

# 脆弱性チェック（簡易版）
OUTDATED_OUTPUT=$(flutter pub outdated 2>&1 || true)
if echo "$OUTDATED_OUTPUT" | grep -q "No dependencies"; then
    check_pass "依存関係: 最新状態"
else
    check_warn "依存関係: 更新可能なパッケージがあります"
fi

# 7. ビルドチェック
echo -e "\n${BLUE}🔨 7. ビルドチェック${NC}"

# Androidビルドチェック
if flutter build apk --debug &> /dev/null; then
    check_pass "Android: デバッグビルド成功"
else
    check_fail "Android: デバッグビルドに失敗"
fi

# iOSビルドチェック（macOSの場合のみ）
if [[ "$OSTYPE" == "darwin"* ]]; then
    if flutter build ios --simulator --debug &> /dev/null; then
        check_pass "iOS: シミュレーターデバッグビルド成功"
    else
        check_fail "iOS: シミュレーターデバッグビルドに失敗"
    fi
fi

# 8. 設定ファイルチェック
echo -e "\n${BLUE}⚙️  8. 設定ファイルチェック${NC}"

# production.yaml チェック
if [ -f "config/production.yaml" ]; then
    if grep -q "environment:" config/production.yaml; then
        check_pass "本番設定: production.yaml が適切に設定されています"
    else
        check_warn "本番設定: production.yaml の設定を確認してください"
    fi
else
    check_fail "本番設定: config/production.yaml が見つかりません"
fi

# 9. APIキー設定チェック
echo -e "\n${BLUE}🔑 9. APIキー設定チェック${NC}"

# 環境変数チェック
if [ -n "$HOTPEPPER_API_KEY" ]; then
    check_pass "HotPepper APIキー: 環境変数に設定済み"
else
    check_warn "HotPepper APIキー: 環境変数未設定（本番では Secure Storage から取得）"
fi

# Google Maps APIキーチェックは削除（WebView実装により不要）
# if [ -n "$GOOGLE_MAPS_API_KEY" ]; then
    check_pass "Google Maps APIキー: 環境変数に設定済み"
else
    check_warn "Google Maps APIキー: 環境変数未設定（本番では Secure Storage から取得）"
fi

# 10. デプロイスクリプトチェック
echo -e "\n${BLUE}🚀 10. デプロイスクリプトチェック${NC}"

if [ -x "scripts/deploy-production.sh" ]; then
    check_pass "デプロイスクリプト: 実行可能"
else
    check_fail "デプロイスクリプト: 実行権限がありません"
fi

if [ -x "scripts/setup-production-keys.sh" ]; then
    check_pass "APIキー設定スクリプト: 実行可能"
else
    check_fail "APIキー設定スクリプト: 実行権限がありません"
fi

# 結果サマリー
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}📊 チェック結果サマリー${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ 合格: $PASSED 項目${NC}"
echo -e "${RED}❌ 失敗: $FAILED 項目${NC}"
echo -e "${YELLOW}⚠️  警告: $WARNINGS 項目${NC}"
echo ""

# 本番リリース判定
if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 本番リリース準備完了！${NC}"
        echo -e "${GREEN}すべてのチェックに合格しました。安心してリリースできます。${NC}"
        exit_code=0
    else
        echo -e "${YELLOW}⚠️  本番リリース注意！${NC}"
        echo -e "${YELLOW}警告項目がありますが、リリース可能です。警告内容を確認してください。${NC}"
        exit_code=0
    fi
else
    echo -e "${RED}🚫 本番リリース未準備！${NC}"
    echo -e "${RED}失敗項目を修正してから再度チェックしてください。${NC}"
    exit_code=1
fi

echo ""
echo -e "${BLUE}📋 次のアクション:${NC}"
if [ $FAILED -eq 0 ]; then
    echo "1. 本番環境でのAPIキー設定: ./scripts/setup-production-keys.sh"
    echo "2. 本番デプロイ実行: ./scripts/deploy-production.sh [ios|android|web]"
    echo "3. リリース後のモニタリング実施"
else
    echo "1. 失敗項目の修正"
    echo "2. 再度チェック実行: ./scripts/check-production-ready.sh"
fi

echo ""
echo -e "${PURPLE}🏁 本番環境準備チェック完了${NC}"

exit $exit_code