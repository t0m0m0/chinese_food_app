#!/bin/bash

# 本番環境デプロイスクリプト
# deploy-production.sh
#
# 使用方法:
#   ./scripts/deploy-production.sh ios
#   ./scripts/deploy-production.sh android
#   ./scripts/deploy-production.sh web

set -e  # エラー時に停止

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # カラーリセット

# ロゴ表示
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              町中華探索アプリ「マチアプ」                    ║"
echo "║                本番環境デプロイスクリプト                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 引数チェック
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ エラー: プラットフォームを指定してください${NC}"
    echo "使用方法: $0 [ios|android|web]"
    exit 1
fi

PLATFORM=$1
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="build/production_${PLATFORM}_${TIMESTAMP}"

echo -e "${BLUE}🚀 本番環境デプロイ開始: ${PLATFORM}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. 前提条件チェック
echo -e "${YELLOW}📋 前提条件チェック中...${NC}"

# Flutter環境チェック
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter SDKが見つかりません${NC}"
    exit 1
fi

# APIキー環境変数チェック
if [ -z "$PROD_HOTPEPPER_API_KEY" ] && [ -z "$HOTPEPPER_API_KEY" ]; then
    echo -e "${RED}❌ HotPepper APIキーが設定されていません${NC}"
    echo "環境変数 PROD_HOTPEPPER_API_KEY または HOTPEPPER_API_KEY を設定してください"
    exit 1
fi

if [ -z "$PROD_GOOGLE_MAPS_API_KEY" ] && [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo -e "${RED}❌ Google Maps APIキーが設定されていません${NC}"
    echo "環境変数 PROD_GOOGLE_MAPS_API_KEY または GOOGLE_MAPS_API_KEY を設定してください"
    exit 1
fi

echo -e "${GREEN}✅ 前提条件チェック完了${NC}"

# 2. プロジェクトクリーンアップ
echo -e "${YELLOW}🧹 プロジェクトクリーンアップ中...${NC}"
flutter clean
flutter pub get

# 3. コード品質チェック
echo -e "${YELLOW}🔍 コード品質チェック中...${NC}"

# フォーマットチェック
if ! dart format --set-exit-if-changed .; then
    echo -e "${RED}❌ コードフォーマットエラー: dart format . を実行してください${NC}"
    exit 1
fi

# 静的解析
if ! flutter analyze; then
    echo -e "${RED}❌ 静的解析エラー: 修正が必要です${NC}"
    exit 1
fi

# テスト実行
echo -e "${YELLOW}🧪 テスト実行中...${NC}"
if ! flutter test; then
    echo -e "${RED}❌ テストエラー: 修正が必要です${NC}"
    exit 1
fi

echo -e "${GREEN}✅ コード品質チェック完了${NC}"

# 4. ビルド
echo -e "${YELLOW}🔨 本番ビルド中...${NC}"
mkdir -p "$BUILD_DIR"

case $PLATFORM in
    "ios")
        echo -e "${BLUE}📱 iOS本番ビルド中...${NC}"
        
        # iOS証明書チェック
        echo "証明書とプロビジョニングプロファイルを確認してください"
        
        # 本番ビルド実行
        flutter build ios \
            --release \
            --dart-define=FLUTTER_ENV=production \
            --dart-define=PRODUCTION=true \
            --dart-define=PROD_HOTPEPPER_API_KEY="$PROD_HOTPEPPER_API_KEY" \
            --dart-define=PROD_GOOGLE_MAPS_API_KEY="$PROD_GOOGLE_MAPS_API_KEY" \
            --build-name=1.0.0 \
            --build-number="$(date +%Y%m%d%H%M)"
            
        # Xcodeアーカイブ作成
        echo -e "${BLUE}📦 Xcodeアーカイブ作成中...${NC}"
        cd ios
        xcodebuild \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -destination generic/platform=iOS \
            -archivePath "../${BUILD_DIR}/Runner.xcarchive" \
            archive
        cd ..
        
        echo -e "${GREEN}✅ iOS本番ビルド完了${NC}"
        echo "アーカイブ場所: ${BUILD_DIR}/Runner.xcarchive"
        echo ""
        echo -e "${YELLOW}📤 次のステップ:${NC}"
        echo "1. Xcode Organizerを開く"
        echo "2. アーカイブを選択してApp Store Connectにアップロード"
        echo "3. App Store Connectでリリース設定"
        ;;
        
    "android")
        echo -e "${BLUE}🤖 Android本番ビルド中...${NC}"
        
        # Android署名キーチェック
        if [ -z "$ANDROID_KEYSTORE_PATH" ] || [ -z "$ANDROID_KEY_ALIAS" ]; then
            echo -e "${YELLOW}⚠️  Android署名キーが未設定です${NC}"
            echo "環境変数を設定してください:"
            echo "- ANDROID_KEYSTORE_PATH"
            echo "- ANDROID_KEY_ALIAS"
            echo "- ANDROID_KEYSTORE_PASSWORD"
            echo "- ANDROID_KEY_PASSWORD"
        fi
        
        # App Bundle作成
        flutter build appbundle \
            --release \
            --dart-define=FLUTTER_ENV=production \
            --dart-define=PRODUCTION=true \
            --dart-define=PROD_HOTPEPPER_API_KEY="$PROD_HOTPEPPER_API_KEY" \
            --dart-define=PROD_GOOGLE_MAPS_API_KEY="$PROD_GOOGLE_MAPS_API_KEY" \
            --build-name=1.0.0 \
            --build-number="$(date +%Y%m%d%H%M)" \
            --obfuscate \
            --split-debug-info="${BUILD_DIR}/debug_symbols"
            
        # ビルド成果物コピー
        cp build/app/outputs/bundle/release/app-release.aab "${BUILD_DIR}/"
        
        echo -e "${GREEN}✅ Android本番ビルド完了${NC}"
        echo "App Bundle場所: ${BUILD_DIR}/app-release.aab"
        echo ""
        echo -e "${YELLOW}📤 次のステップ:${NC}"
        echo "1. Google Play Consoleにログイン"
        echo "2. アプリを選択し、「リリース」> 「本番環境」"
        echo "3. App Bundleをアップロード"
        ;;
        
    "web")
        echo -e "${BLUE}🌐 Web本番ビルド中...${NC}"
        
        flutter build web \
            --release \
            --dart-define=FLUTTER_ENV=production \
            --dart-define=PRODUCTION=true \
            --dart-define=PROD_HOTPEPPER_API_KEY="$PROD_HOTPEPPER_API_KEY" \
            --dart-define=PROD_GOOGLE_MAPS_API_KEY="$PROD_GOOGLE_MAPS_API_KEY" \
            --web-renderer=html \
            --base-href="/"
            
        # ビルド成果物コピー
        cp -r build/web "${BUILD_DIR}/"
        
        echo -e "${GREEN}✅ Web本番ビルド完了${NC}"
        echo "Webビルド場所: ${BUILD_DIR}/web/"
        echo ""
        echo -e "${YELLOW}📤 次のステップ:${NC}"
        echo "1. Webサーバーに ${BUILD_DIR}/web/ の内容をアップロード"
        echo "2. HTTPSを有効化"
        echo "3. セキュリティヘッダーを設定"
        ;;
        
    *)
        echo -e "${RED}❌ 不正なプラットフォーム: $PLATFORM${NC}"
        echo "対応プラットフォーム: ios, android, web"
        exit 1
        ;;
esac

# 5. デプロイ完了
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 本番環境デプロイ準備完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 ビルド情報:${NC}"
echo "プラットフォーム: $PLATFORM"
echo "ビルド時刻: $(date)"
echo "ビルドディレクトリ: $BUILD_DIR"
echo ""
echo -e "${YELLOW}⚠️  重要な注意事項:${NC}"
echo "1. 本番環境でのテストを十分に実施してください"
echo "2. ロールバック計画を準備してください"
echo "3. ユーザーへの告知を検討してください"
echo "4. リリース後のモニタリングを実施してください"
echo ""
echo -e "${GREEN}🚀 デプロイスクリプト完了${NC}"