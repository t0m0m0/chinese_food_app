#!/bin/bash
# .github/scripts/setup-test-env.sh
# CI環境でのテスト用環境変数設定スクリプト

set -e  # エラー時に停止
set -x  # コマンドを表示

echo "=== リポジトリの.env.testファイルを使用 ==="
echo "ファイル存在確認:"
ls -la .env.test

echo "=== .env.testファイル内容確認 ==="
cat .env.test

echo "=== CI用追加設定を.env.testに追記 ==="
echo "TEST_ENV_SOURCE=ci" >> .env.test
echo "CI_ENVIRONMENT=github_actions" >> .env.test

echo "=== 最終的な.env.testファイル内容 ==="
cat .env.test

echo "=== CI環境用の.envファイル作成（.env.testベース） ==="
# CI環境ではpubspec.yamlのassetsで.envが要求されるため、.env.testをベースに作成
if [ ! -f .env ]; then
  # .env.testから基本的なAPIキー設定をコピー
  grep -E '^(HOTPEPPER_API_KEY|GOOGLE_MAPS_API_KEY|FLUTTER_ENV)=' .env.test > .env || true
  echo "# CI環境用ファイル（.env.testから生成）" >> .env
  echo "Created .env file from .env.test for CI environment"
  echo "Generated .env content:"
  cat .env
fi

echo "=== DotEnv初期化のための環境変数設定 ==="
# Flutter test実行時にDotEnvが.env.testを読み込むように環境変数で指示
export FLUTTER_TEST_ENV_FILE=".env.test"
export DOTENV_FILE=".env.test"

echo "✅ テスト環境設定完了"