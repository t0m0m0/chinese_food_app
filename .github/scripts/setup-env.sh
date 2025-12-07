#!/bin/bash
# .github/scripts/setup-env.sh
# CI環境でのテスト用環境変数設定スクリプト（簡易版）

set -e  # エラー時に停止

echo "=== テスト用.envファイル作成 ==="
# テスト用の.env.testファイルがCI環境で使えるように.envとしてコピー
if [ -f ".env.test" ]; then
  cp .env.test .env
  echo "TEST_ENV_SOURCE=ci" >> .env.test
  echo "CI_ENVIRONMENT=github_actions" >> .env.test
  echo "✅ .env.testファイルから.envを作成しました"
else
  echo "FLUTTER_ENV=test" > .env
  echo "HOTPEPPER_API_KEY=test_dummy_key_12345" >> .env
  echo "✅ デフォルトのテスト用.envファイルを作成しました"
fi
