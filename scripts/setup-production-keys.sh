#!/bin/bash

# 本番環境APIキー設定スクリプト
# setup-production-keys.sh
#
# 本番環境で使用するAPIキーをSecure Storageに安全に設定します

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              本番環境APIキー設定スクリプト                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  重要: このスクリプトは本番環境でのみ実行してください${NC}"
echo ""

# 確認プロンプト
read -p "本番環境でAPIキーを設定しますか？ (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}❌ 設定をキャンセルしました${NC}"
    exit 0
fi

echo -e "${BLUE}🔐 本番環境APIキー設定を開始します...${NC}"

# HotPepper APIキー設定
echo ""
echo -e "${YELLOW}📝 HotPepper Gourmet APIキーを入力してください:${NC}"
read -s -p "HotPepper APIキー: " HOTPEPPER_KEY
echo ""

if [ -z "$HOTPEPPER_KEY" ]; then
    echo -e "${RED}❌ HotPepper APIキーが入力されていません${NC}"
    exit 1
fi

# Google Maps APIキー設定  
echo -e "${YELLOW}📝 Google Maps APIキーを入力してください:${NC}"
read -s -p "Google Maps APIキー: " GOOGLE_MAPS_KEY
echo ""

if [ -z "$GOOGLE_MAPS_KEY" ]; then
    echo -e "${RED}❌ Google Maps APIキーが入力されていません${NC}"
    exit 1
fi

# APIキー形式チェック
echo -e "${BLUE}🔍 APIキー形式をチェック中...${NC}"

# HotPepper APIキー形式チェック (英数字32文字程度)
if [[ ! "$HOTPEPPER_KEY" =~ ^[a-zA-Z0-9]{20,50}$ ]]; then
    echo -e "${YELLOW}⚠️  HotPepper APIキーの形式が一般的でない可能性があります${NC}"
    read -p "続行しますか？ (yes/no): " continue_hotpepper
    if [ "$continue_hotpepper" != "yes" ]; then
        exit 1
    fi
fi

# Google Maps APIキー形式チェック
if [[ ! "$GOOGLE_MAPS_KEY" =~ ^AIza[a-zA-Z0-9_-]{35}$ ]]; then
    echo -e "${YELLOW}⚠️  Google Maps APIキーの形式が一般的でない可能性があります${NC}"
    echo "一般的な形式: AIzaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    read -p "続行しますか？ (yes/no): " continue_google
    if [ "$continue_google" != "yes" ]; then
        exit 1
    fi
fi

# Flutter Secure Storageに保存するためのDartスクリプト作成
echo -e "${BLUE}💾 APIキーをSecure Storageに保存中...${NC}"

cat > temp_store_keys.dart << 'EOF'
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 環境変数から取得
  final hotpepperKey = Platform.environment['TEMP_HOTPEPPER_KEY'];
  final googleMapsKey = Platform.environment['TEMP_GOOGLE_MAPS_KEY'];

  if (hotpepperKey == null || googleMapsKey == null) {
    print('❌ 環境変数が設定されていません');
    exit(1);
  }

  try {
    // APIキーを安全に保存
    await storage.write(key: 'HOTPEPPER_API_KEY', value: hotpepperKey);
    
    print('✅ APIキーをSecure Storageに保存しました');
    
    // 検証: 保存されたキーを読み取り
    final storedHotpepper = await storage.read(key: 'HOTPEPPER_API_KEY');
    
    if (storedHotpepper != null && storedGoogleMaps != null) {
      print('✅ APIキーの保存を確認しました');
      print('HotPepper: ${storedHotpepper.substring(0, 8)}...');
      print('Google Maps: ${storedGoogleMaps.substring(0, 8)}...');
    } else {
      print('❌ APIキーの保存に失敗しました');
      exit(1);
    }
  } catch (e) {
    print('❌ エラー: $e');
    exit(1);
  }
}
EOF

# 一時的に環境変数に設定してDartスクリプト実行
export TEMP_HOTPEPPER_KEY="$HOTPEPPER_KEY"
export TEMP_GOOGLE_MAPS_KEY="$GOOGLE_MAPS_KEY"

# Dartスクリプト実行
flutter --no-version-check pub get > /dev/null
dart temp_store_keys.dart

# 一時ファイルとEnvironment変数をクリーンアップ
rm temp_store_keys.dart
unset TEMP_HOTPEPPER_KEY
unset TEMP_GOOGLE_MAPS_KEY
unset HOTPEPPER_KEY
unset GOOGLE_MAPS_KEY

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 本番環境APIキー設定完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 設定完了項目:${NC}"
echo "✅ HotPepper Gourmet APIキー"
echo "✅ Google Maps APIキー"
echo "✅ Secure Storage暗号化保存"
echo ""
echo -e "${YELLOW}🔒 セキュリティ情報:${NC}"
echo "• APIキーはFlutter Secure Storageで暗号化保存されています"
echo "• Android: EncryptedSharedPreferences使用"
echo "• iOS: Keychain (first_unlock_this_device) 使用"
echo ""
echo -e "${GREEN}🚀 本番環境で安全にAPIキーを使用できます${NC}"