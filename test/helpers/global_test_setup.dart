import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';

/// グローバルなテストセットアップ
/// 全テストの実行前に一度だけ実行される
void setupGlobalTestEnvironment() {
  setUpAll(() async {
    // CI環境では.env.testファイルを優先使用
    try {
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // フォールバック：.env.testが存在しない場合
      dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing

FLUTTER_ENV=development
TEST_DATABASE_PATH=:memory:
ENABLE_DEBUG_LOGGING=false
ENABLE_PERFORMANCE_MONITORING=false
TEST_TIMEOUT_SECONDS=30
TEST_MAX_RETRY_COUNT=3
''');
    }

    // EnvironmentConfigを初期化
    try {
      await EnvironmentConfig.initialize();
    } catch (e) {
      // 既に初期化済みの場合は無視
    }
  });
}
