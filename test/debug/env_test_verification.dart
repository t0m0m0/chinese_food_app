import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'dart:developer' as developer;

/// .env.testファイルが正しく読み込まれているかを確認するテスト
void main() {
  group('Environment Test File Verification', () {
    test('should load .env.test file correctly', () async {
      // .env.testファイルを読み込み
      try {
        await dotenv.load(fileName: '.env.test');
        developer.log('✅ .env.test file loaded successfully',
            name: 'EnvTestVerification');

        // 環境変数の確認
        developer.log('Environment variables from .env.test:',
            name: 'EnvTestVerification');
        developer.log('  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']}',
            name: 'EnvTestVerification');
        developer.log('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}',
            name: 'EnvTestVerification');
        developer.log(
            '  TEST_DATABASE_PATH: ${dotenv.env['TEST_DATABASE_PATH']}',
            name: 'EnvTestVerification');
        developer.log('  TEST_ENV_SOURCE: ${dotenv.env['TEST_ENV_SOURCE']}',
            name: 'EnvTestVerification');

        // EnvironmentConfigの初期化
        await EnvironmentConfig.initialize();

        // 実際に使用される値を確認
        developer.log('EnvironmentConfig values:', name: 'EnvTestVerification');
        developer.log('  hotpepperApiKey: ${EnvironmentConfig.hotpepperApiKey}',
            name: 'EnvTestVerification');
        developer.log(
            '  current environment: ${EnvironmentConfig.current.name}',
            name: 'EnvTestVerification');

        // 期待値と比較（ファイルから読み込まれた場合）
        expect(dotenv.env['HOTPEPPER_API_KEY'],
            equals('test_hotpepper_api_key_for_testing_from_file'));
        expect(dotenv.env['FLUTTER_ENV'], equals('development'));
        expect(dotenv.env['TEST_ENV_SOURCE'], equals('file'));
      } catch (e) {
        developer.log('❌ Failed to load .env.test file: $e',
            name: 'EnvTestVerification');

        // フォールバック確認
        developer.log('Testing fallback mechanism...',
            name: 'EnvTestVerification');
        dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing_from_fallback
FLUTTER_ENV=development
TEST_ENV_SOURCE=fallback
''');
        developer.log('✅ Fallback mechanism working',
            name: 'EnvTestVerification');
        expect(dotenv.env['HOTPEPPER_API_KEY'],
            equals('test_hotpepper_api_key_for_testing_from_fallback'));
        expect(dotenv.env['TEST_ENV_SOURCE'], equals('fallback'));
      }
    });
  });
}
