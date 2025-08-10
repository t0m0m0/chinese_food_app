#!/bin/bash
# Android リリース署名設定スクリプト
# 中華料理アプリ「マチアプ」用

set -e

# 色付き出力の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# スクリプト情報表示
echo "=================================="
echo "🔐 Android リリース署名設定"
echo "=================================="
echo ""

# 環境変数確認関数
check_env_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
        log_error "$var_name が設定されていません"
        return 1
    else
        log_success "$var_name が設定されています"
        return 0
    fi
}

# 署名設定確認
log_info "署名設定を確認しています..."
echo ""

# 必要な環境変数一覧
required_vars=("RELEASE_STORE_FILE" "RELEASE_KEY_ALIAS" "RELEASE_STORE_PASSWORD" "RELEASE_KEY_PASSWORD")
missing_vars=()

# 環境変数チェック
for var in "${required_vars[@]}"; do
    if ! check_env_var "$var"; then
        missing_vars+=("$var")
    fi
done

# 結果判定
if [ ${#missing_vars[@]} -eq 0 ]; then
    log_success "全ての署名設定が完了しています！"
    echo ""
    
    # keystoreファイルの存在確認
    if [ -f "$RELEASE_STORE_FILE" ]; then
        log_success "Keystoreファイルが見つかりました: $RELEASE_STORE_FILE"
    else
        log_error "Keystoreファイルが見つかりません: $RELEASE_STORE_FILE"
        exit 1
    fi
    
    # 署名設定テスト
    log_info "署名設定をテストしています..."
    
    # Gradleで署名設定確認
    cd "$(dirname "$0")/.."
    if ./gradlew -p android assembleRelease --dry-run > /dev/null 2>&1; then
        log_success "署名設定のテストが成功しました！"
    else
        log_warning "署名設定のテストで警告が発生しました。手動確認を推奨します。"
    fi
    
else
    log_error "以下の環境変数が不足しています："
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    
    log_info "設定例："
    echo "export RELEASE_STORE_FILE=/path/to/release.keystore"
    echo "export RELEASE_KEY_ALIAS=release_key"
    echo "export RELEASE_STORE_PASSWORD=your_store_password"
    echo "export RELEASE_KEY_PASSWORD=your_key_password"
    echo ""
    
    log_warning "セキュリティのため、これらの値は.envファイルや環境変数で管理してください"
    exit 1
fi

# 署名用コマンド例を表示
echo ""
log_info "リリースビルドコマンド例："
echo "flutter build appbundle --release"
echo "flutter build apk --release"
echo ""

log_success "署名設定の確認が完了しました！"