#!/bin/bash
# .github/scripts/setup-build-env.sh
# CI環境でのビルド用環境変数設定スクリプト

set -e  # エラー時に停止

echo "FLUTTER_ENV=production" > .env

# 本番用APIキーがある場合は使用、なければダミー値
if [ -n "$HOTPEPPER_API_KEY_PROD" ]; then
    echo "HOTPEPPER_API_KEY=$HOTPEPPER_API_KEY_PROD" >> .env
else
    echo "HOTPEPPER_API_KEY=dummy_hotpepper_key_for_build_12345" >> .env
fi


echo "=== ビルド用環境ファイル確認（機密情報はマスク） ==="
sed 's/API_KEY=.*/API_KEY=***MASKED***/g' .env

echo "✅ ビルド環境設定完了"