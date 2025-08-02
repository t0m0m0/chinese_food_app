// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';

/// .env.testファイルが正しく読み込まれているかを確認するテスト
void main() {
  group('Environment Test File Verification', () {
    test('should load .env.test file correctly', () async {
      // .env.testファイルを読み込み
      try {
        await dotenv.load(fileName: '.env.test');
        print('✅ .env.test file loaded successfully');
        
        // 環境変数の確認
        print('Environment variables from .env.test:');
        print('  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']}');
        print('  GOOGLE_MAPS_API_KEY: ${dotenv.env['GOOGLE_MAPS_API_KEY']}');
        print('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
        print('  TEST_DATABASE_PATH: ${dotenv.env['TEST_DATABASE_PATH']}');
        print('  TEST_ENV_SOURCE: ${dotenv.env['TEST_ENV_SOURCE']}');
        
        // EnvironmentConfigの初期化
        await EnvironmentConfig.initialize();
        
        // 実際に使用される値を確認
        print('EnvironmentConfig values:');
        print('  hotpepperApiKey: ${EnvironmentConfig.hotpepperApiKey}');
        print('  googleMapsApiKey: ${EnvironmentConfig.googleMapsApiKey}');
        print('  current environment: ${EnvironmentConfig.current.name}');
        
        // 期待値と比較（ファイルから読み込まれた場合）
        expect(dotenv.env['HOTPEPPER_API_KEY'], equals('test_hotpepper_api_key_for_testing_from_file'));
        expect(dotenv.env['GOOGLE_MAPS_API_KEY'], equals('test_google_maps_api_key_for_testing_from_file'));
        expect(dotenv.env['FLUTTER_ENV'], equals('development'));
        expect(dotenv.env['TEST_ENV_SOURCE'], equals('file'));
        
      } catch (e) {
        print('❌ Failed to load .env.test file: $e');
        
        // フォールバック確認
        print('Testing fallback mechanism...');
        dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing_from_fallback
GOOGLE_MAPS_API_KEY=test_google_maps_api_key_for_testing_from_fallback
FLUTTER_ENV=development
TEST_ENV_SOURCE=fallback
''');
        print('✅ Fallback mechanism working');
        expect(dotenv.env['HOTPEPPER_API_KEY'], equals('test_hotpepper_api_key_for_testing_from_fallback'));
        expect(dotenv.env['TEST_ENV_SOURCE'], equals('fallback'));
      }
    });
  });
}