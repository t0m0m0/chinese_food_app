// test/helpers/test_env_setup.dart
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'test_constants.dart';

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
        developer.log('✅ .env.test file loaded successfully', name: 'TestEnvSetup');
      }
    } catch (e) {
      // .env.testファイルが存在しない場合はデフォルト値を設定
      if (enableDebugLogging) {
        developer.log('Warning: .env.test file not found, using default test values', name: 'TestEnvSetup');
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
        developer.log('ConfigManager initialization failed: $e', name: 'TestEnvSetup');
      }
      // テスト環境では初期化エラーを無視
    }

    _isInitialized = true;
  }

  static void _setDefaultTestValues() {
    try {
      // DotEnvが初期化済みの場合、不足している設定値を補完
      _ensureRequiredEnvironmentVariables();
    } catch (e) {
      // 初期化エラーの場合はデフォルト設定で強制初期化
      _initializeWithDefaults();
    }
  }

  /// 必要な環境変数が設定されていることを確認し、不足している場合は補完
  static void _ensureRequiredEnvironmentVariables() {
    // DotEnvアクセステスト（NotInitializedErrorを発生させる可能性あり）
    final env = dotenv.env;

    // 必要な設定値を補完
    env[TestConstants.hotpepperApiKeyEnv] ??=
        TestConstants.dummyHotpepperApiKey;
    env[TestConstants.googleMapsApiKeyEnv] ??=
        TestConstants.dummyGoogleMapsApiKey;
    env[TestConstants.flutterEnvKey] ??= TestConstants.testEnvValue;

    // 空の値をデフォルト値で置き換え
    if (env[TestConstants.hotpepperApiKeyEnv]?.isEmpty ?? false) {
      env[TestConstants.hotpepperApiKeyEnv] =
          TestConstants.dummyHotpepperApiKey;
    }
    if (env[TestConstants.googleMapsApiKeyEnv]?.isEmpty ?? false) {
      env[TestConstants.googleMapsApiKeyEnv] =
          TestConstants.dummyGoogleMapsApiKey;
    }
  }

  /// デフォルト設定でDotEnvを強制初期化
  static void _initializeWithDefaults() {
    try {
      dotenv.testLoad(fileInput: TestConstants.defaultTestEnvironmentConfig);
    } catch (e) {
      // 初期化に失敗した場合はエラーをログ出力して続行
      developer.log('Failed to initialize test environment with defaults: $e', name: 'TestEnvSetup', level: 1000);
    }
  }

  static void cleanupTestEnvironment() {
    if (!_isInitialized) return;

    // テスト用の環境変数をクリア
    dotenv.env.clear();
    _isInitialized = false;
  }

  /// テスト用APIキーを設定
  static void setTestApiKey(String key, String value) {
    try {
      dotenv.env[key] = value;
    } catch (e) {
      developer.log('Warning: Failed to set test API key $key: $e', name: 'TestEnvSetup', level: 900);
    }
  }

  /// テスト用APIキーをクリア
  static void clearTestApiKey(String key) {
    try {
      dotenv.env.remove(key);
    } catch (e) {
      developer.log('Warning: Failed to clear test API key $key: $e', name: 'TestEnvSetup', level: 900);
    }
  }
}
