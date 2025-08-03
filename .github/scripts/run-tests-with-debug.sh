#!/bin/bash
# .github/scripts/run-tests-with-debug.sh
# CI環境でのテスト実行とデバッグ情報出力スクリプト

set -e  # エラー時に停止

echo "=== テスト実行前の環境確認 ==="
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

echo "Content of .env.test:"
cat .env.test 2>/dev/null || echo ".env.test file not found"

echo "=== テスト環境の初期化確認 ==="
# TestEnvSetupの初期化を確実に実行するため、事前に簡単なテストを実行
echo "Testing environment setup..."
flutter test test/helpers/ --reporter=expanded || echo "Environment setup test completed with warnings"

echo "=== Flutter test開始 ==="
flutter test --coverage --reporter=expanded

echo "=== テスト完了 ==="
echo "✅ 全テスト実行完了"