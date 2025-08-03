#!/bin/bash
# .github/scripts/setup-integration-test-env.sh
# 統合テスト用環境設定スクリプト

set -e  # エラー時に停止

echo "FLUTTER_ENV=integration" > .env.integration
echo "HOTPEPPER_API_KEY=integration_test_key_12345" >> .env.integration
echo "GOOGLE_MAPS_API_KEY=integration_test_maps_key_12345" >> .env.integration
echo "LOCATION_MODE=mock" >> .env.integration

echo "=== 統合テスト環境設定完了 ==="
cat .env.integration

echo "✅ 統合テスト環境設定完了"