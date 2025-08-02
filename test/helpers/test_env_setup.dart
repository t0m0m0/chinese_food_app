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
    bool loadedFromFile = false;

    // 複数のパスで.env.testファイルを探索
    final possiblePaths = ['.env.test', '../.env.test', '../../.env.test'];

    for (final path in possiblePaths) {
      try {
        await dotenv.load(fileName: path);
        loadedFromFile = true;
        if (enableDebugLogging) {
          print('✅ .env.testファイルから環境変数を読み込みました (パス: $path)');
          print(
              '  - HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']?.substring(0, 8)}...');
          print(
              '  - GOOGLE_MAPS_API_KEY: ${dotenv.env['GOOGLE_MAPS_API_KEY']?.substring(0, 8)}...');
        }
        break;
      } catch (e) {
        if (enableDebugLogging) {
          print('⚠️ パス $path での.env.testファイル読み込み失敗: $e');
        }
        continue;
      }
    }

    // どのパスでも読み込めなかった場合はフォールバック
    if (!loadedFromFile) {
      if (enableDebugLogging) {
        print('⚠️ 全てのパスで.env.testファイル読み込み失敗');
        print('フォールバック値を使用します');
      }
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

    // 確実にAPIキーが設定されているかチェック
    final hotpepperKey = dotenv.env['HOTPEPPER_API_KEY'] ?? '';
    final googleMapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    if (enableDebugLogging) {
      print('DotEnv状態確認:');
      print('  - ファイルから読み込み: $loadedFromFile');
      print('  - HotPepper APIキー設定済み: ${hotpepperKey.isNotEmpty}');
      print('  - Google Maps APIキー設定済み: ${googleMapsKey.isNotEmpty}');
    }

    // APIキーが設定されていない場合は強制的に設定
    if (hotpepperKey.isEmpty || googleMapsKey.isEmpty) {
      if (enableDebugLogging) {
        print('🔧 APIキーが不足しているため、強制的に設定します');
      }
      dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing_forced
GOOGLE_MAPS_API_KEY=test_google_maps_api_key_for_testing_forced
FLUTTER_ENV=development
TEST_DATABASE_PATH=:memory:
ENABLE_DEBUG_LOGGING=false
ENABLE_PERFORMANCE_MONITORING=false
TEST_TIMEOUT_SECONDS=30
TEST_MAX_RETRY_COUNT=3
TEST_ENV_SOURCE=forced
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
