import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  setUpAll(() async {
    await TestEnvSetup.initializeTestEnvironment(
      throwOnValidationError: false,
      enableDebugLogging: false,
    );
  });

  tearDownAll(() {
    TestEnvSetup.cleanupTestEnvironment();
  });

  group('EnvironmentConfig', () {
    group('Environment enum', () {
      test('should have correct environment names', () {
        expect(Environment.development.name, 'development');
        expect(Environment.staging.name, 'staging');
        expect(Environment.production.name, 'production');
      });
    });

    group('current environment', () {
      test('should default to development when FLUTTER_ENV is not set', () {
        expect(EnvironmentConfig.current, Environment.development);
      });

      test('should return correct environment flags', () {
        expect(EnvironmentConfig.isDevelopment, isTrue);
        expect(EnvironmentConfig.isStaging, isFalse);
        expect(EnvironmentConfig.isProduction, isFalse);
      });
    });

    group('API keys', () {
      test('should return API keys from .env.test file when available', () {
        final hotpepperKey = EnvironmentConfig.hotpepperApiKey;
        final googleMapsKey = EnvironmentConfig.googleMapsApiKey;

        // テスト環境では最低限の長さがあることを確認
        expect(hotpepperKey.length, greaterThan(10),
            reason: 'HotPepper APIキーが短すぎます。実際の値の長さ: ${hotpepperKey.length}');
        expect(googleMapsKey.length, greaterThan(10),
            reason: 'Google Maps APIキーが短すぎます。実際の値の長さ: ${googleMapsKey.length}');

        // テスト用のキーかどうかを確認
        expect(hotpepperKey,
            anyOf(contains('test_dummy'), hasLength(greaterThan(20))));
        expect(googleMapsKey,
            anyOf(contains('test_dummy'), hasLength(greaterThan(20))));
      });

      test('should use effective API keys', () {
        final effectiveHotpepperKey =
            EnvironmentConfig.effectiveHotpepperApiKey;
        final effectiveGoogleMapsKey =
            EnvironmentConfig.effectiveGoogleMapsApiKey;

        expect(effectiveHotpepperKey, isNotEmpty,
            reason: 'Effective HotPepper APIキーが空です。');
        expect(effectiveGoogleMapsKey, isNotEmpty,
            reason: 'Effective Google Maps APIキーが空です。');
      });
    });

    group('API URL', () {
      test('should return correct HotPepper API URL', () {
        const expectedUrl =
            'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
        expect(EnvironmentConfig.hotpepperApiUrl, expectedUrl);
      });
    });

    group('debug info', () {
      test('should provide debug information', () {
        final debugInfo = EnvironmentConfig.debugInfo;

        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo['environment'], 'development');
        expect(debugInfo['hotpepperApiUrl'],
            'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');

        // APIキーは設定されているか、マスクされているかのいずれか
        final hotpepperKey = debugInfo['hotpepperApiKey'] as String;
        expect(
            hotpepperKey,
            anyOf(
              matches(r'^.{8}\.\.\.'), // マスクされた形式
              equals('(未設定)'), // 未設定の場合
              contains('test_dummy'), // テストダミー値
            ));
      });

      test('should mask API keys in debug info when available', () {
        final debugInfo = EnvironmentConfig.debugInfo;

        final hotpepperKey = debugInfo['hotpepperApiKey'] as String;
        final googleMapsKey = debugInfo['googleMapsApiKey'] as String;

        // キーが設定されている場合はマスクされる、または未設定として表示される
        expect(
            hotpepperKey,
            anyOf(
              equals('(未設定)'),
              matches(r'^.{8}\.\.\.'),
              contains('test_dummy'),
            ));

        expect(
            googleMapsKey,
            anyOf(
              equals('(未設定)'),
              matches(r'^.{8}\.\.\.'),
              contains('test_dummy'),
            ));
      });
    });
  });
}
