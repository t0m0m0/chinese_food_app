import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';

/// テスト環境のセットアップを行うヘルパークラス
class TestEnvSetup {
  /// テスト用の環境変数を初期化
  static Future<void> initializeTestEnvironment({
    bool throwOnValidationError = false,
    bool enableDebugLogging = false,
  }) async {
    // CI環境では.env.testファイルを優先使用、フォールバックでtestLoad
    try {
      // プロジェクトルートから.env.testを読み込み
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // .env.testが存在しないかアクセスできない場合はフォールバック
      dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing_from_fallback
GOOGLE_MAPS_API_KEY=test_google_maps_api_key_for_testing_from_fallback
FLUTTER_ENV=development
TEST_DATABASE_PATH=:memory:
ENABLE_DEBUG_LOGGING=false
ENABLE_PERFORMANCE_MONITORING=false
TEST_TIMEOUT_SECONDS=30
TEST_MAX_RETRY_COUNT=3
TEST_ENV_SOURCE=fallback
''');
    }

    // EnvironmentConfigを初期化（既に初期化済みの場合はスキップ）
    try {
      await EnvironmentConfig.initialize();
    } catch (e) {
      // 既に初期化済みの場合は無視
    }

    // ConfigManagerを強制的にリセットしてから初期化
    ConfigManager.forceInitialize();
    await ConfigManager.initialize(
      throwOnValidationError: throwOnValidationError,
      enableDebugLogging: enableDebugLogging,
    );

    // テスト用APIキーを設定
    ConfigManager.setValue(
        'hotpepperApiKey', 'test_hotpepper_api_key_for_testing');
    ConfigManager.setValue(
        'googleMapsApiKey', 'test_google_maps_api_key_for_testing');
  }

  /// テスト環境をクリーンアップ
  static void cleanupTestEnvironment() {
    ConfigManager.forceInitialize();
  }
}
