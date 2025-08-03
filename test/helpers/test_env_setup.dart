// test/helpers/test_env_setup.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';

class TestEnvSetup {
  static bool _isInitialized = false;

  static Future<void> initializeTestEnvironment({
    bool throwOnValidationError = false,
    bool enableDebugLogging = false,
  }) async {
    if (_isInitialized) return;

    try {
      // .env.testファイルを読み込み
      await dotenv.load(fileName: ".env.test");
      if (enableDebugLogging) {
        print('✅ .env.test file loaded successfully');
      }
    } catch (e) {
      // .env.testファイルが存在しない場合はデフォルト値を設定
      if (enableDebugLogging) {
        print('Warning: .env.test file not found, using default test values');
      }
    }

    // テスト用のダミーAPIキーを設定（.env.testに値がない場合）
    _setDefaultTestValues();

    try {
      // ConfigManagerを初期化
      await ConfigManager.initialize(
        throwOnValidationError: throwOnValidationError,
      );
    } catch (e) {
      if (enableDebugLogging) {
        print('ConfigManager initialization failed: $e');
      }
      // テスト環境では初期化エラーを無視
    }

    _isInitialized = true;
  }

  static void _setDefaultTestValues() {
    // DotEnvが初期化されていない場合の安全なチェックと初期化
    try {
      // DotEnvが利用できるかテスト
      final testAccess = dotenv.env;
      
      // HotPepper APIキーが設定されていない場合はテスト用の値を設定
      if (dotenv.env['HOTPEPPER_API_KEY']?.isEmpty ?? true) {
        dotenv.env['HOTPEPPER_API_KEY'] =
            'test_dummy_hotpepper_key_for_testing_12345';
      }

      // Google Maps APIキーが設定されていない場合はテスト用の値を設定
      if (dotenv.env['GOOGLE_MAPS_API_KEY']?.isEmpty ?? true) {
        dotenv.env['GOOGLE_MAPS_API_KEY'] =
            'test_dummy_google_maps_key_for_testing_12345';
      }

      // その他のテスト用環境変数
      dotenv.env['FLUTTER_ENV'] ??= 'test';
    } on NotInitializedError {
      // DotEnvが初期化されていない場合は強制的に初期化
      dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=test_dummy_hotpepper_key_for_testing_12345
GOOGLE_MAPS_API_KEY=test_dummy_google_maps_key_for_testing_12345
LOCATION_MODE=test
PERMISSION_TEST_MODE=mock
TEST_DEBUG_LOGGING=true
''');
    } catch (e) {
      // その他のエラーの場合もtestLoadで初期化を試行
      try {
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=test_dummy_hotpepper_key_for_testing_12345
GOOGLE_MAPS_API_KEY=test_dummy_google_maps_key_for_testing_12345
LOCATION_MODE=test
PERMISSION_TEST_MODE=mock
TEST_DEBUG_LOGGING=true
''');
      } catch (initError) {
        // 初期化も失敗した場合はエラーをログに出力
        print('Failed to initialize test environment: $initError');
      }
    }
  }

  static void cleanupTestEnvironment() {
    if (!_isInitialized) return;

    // テスト用の環境変数をクリア
    dotenv.env.clear();
    _isInitialized = false;
  }

  static void setTestApiKey(String key, String value) {
    dotenv.env[key] = value;
  }

  static void clearTestApiKey(String key) {
    dotenv.env.remove(key);
  }
}