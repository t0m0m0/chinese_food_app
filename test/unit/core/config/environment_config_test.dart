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
        expect(Environment.test.name, 'test');
        expect(Environment.staging.name, 'staging');
        expect(Environment.production.name, 'production');
      });
    });

    group('current environment', () {
      test('should be test environment when initialized with TestEnvSetup', () {
        expect(EnvironmentConfig.current, Environment.test);
      });

      test('should return correct environment flags', () {
        expect(EnvironmentConfig.isDevelopment, isFalse);
        expect(EnvironmentConfig.isTest, isTrue);
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
        // Google Maps APIは不要（WebView実装により常に空文字列）
        expect(googleMapsKey, equals(''),
            reason: 'Google Maps APIキーはWebView実装により不要です');

        // テスト用のキーかどうかを確認
        expect(hotpepperKey,
            anyOf(contains('test_dummy'), hasLength(greaterThan(20))));
      });

      test('should use effective API keys', () {
        final effectiveHotpepperKey =
            EnvironmentConfig.effectiveHotpepperApiKey;
        final effectiveGoogleMapsKey =
            EnvironmentConfig.effectiveGoogleMapsApiKey;

        expect(effectiveHotpepperKey, isNotEmpty,
            reason: 'Effective HotPepper APIキーが空です。');
        // Google Maps APIは不要（WebView実装により常に空文字列）
        expect(effectiveGoogleMapsKey, equals(''),
            reason: 'Effective Google Maps APIキーはWebView実装により不要です。');
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
        expect(debugInfo['environment'], 'test');
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

        // Google Maps APIは不要（WebView実装により表示メッセージが異なる）
        expect(
            googleMapsKey,
            anyOf(
              equals('(未設定)'),
              matches(r'^.{8}\.\.\.'),
              contains('test_dummy'),
              equals('(未使用：WebView実装)'),
            ));
      });
    });
  });
}
