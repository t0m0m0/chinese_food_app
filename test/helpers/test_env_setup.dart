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
    // dotenvをテスト環境用に初期化
    try {
      // まず.env.testファイルの読み込みを試行
      await dotenv.load(fileName: '.env.test');
    } catch (e) {
      // .env.testが存在しない場合は、テストデータを直接設定
      dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing
GOOGLE_MAPS_API_KEY=test_google_maps_api_key_for_testing
FLUTTER_ENV=development
''');
    }

    // EnvironmentConfigを初期化
    await EnvironmentConfig.initialize();

    // ConfigManagerをテスト用に初期化
    await ConfigManager.initialize(
      throwOnValidationError: throwOnValidationError,
      enableDebugLogging: enableDebugLogging,
    );

    // テスト用APIキーを設定
    ConfigManager.setValue('hotpepperApiKey', 'test_hotpepper_api_key_for_testing');
    ConfigManager.setValue('googleMapsApiKey', 'test_google_maps_api_key_for_testing');
  }

  /// テスト環境をクリーンアップ
  static void cleanupTestEnvironment() {
    ConfigManager.forceInitialize();
  }
}