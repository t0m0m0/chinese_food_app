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
        // Note: In test environment, String.fromEnvironment defaults are used
        expect(EnvironmentConfig.current, Environment.development);
      });

      test('should return correct environment flags', () {
        // Based on default development environment
        expect(EnvironmentConfig.isDevelopment, isTrue);
        expect(EnvironmentConfig.isStaging, isFalse);
        expect(EnvironmentConfig.isProduction, isFalse);
      });
    });

    group('API keys', () {
      test('should return API keys from .env.test file when available', () {
        // .env.testファイルまたはTestEnvSetupからAPIキーが読み込まれることを確認
        final hotpepperKey = EnvironmentConfig.hotpepperApiKey;
        final googleMapsKey = EnvironmentConfig.googleMapsApiKey;

        // CI環境では.env.testまたはフォールバック値が設定される
        expect(hotpepperKey, isNotEmpty,
            reason: 'HotPepper APIキーが設定されていません。実際の値: "$hotpepperKey"');
        expect(googleMapsKey, isNotEmpty,
            reason: 'Google Maps APIキーが設定されていません。実際の値: "$googleMapsKey"');
      });

      test('should use effective API keys', () {
        // .env.testファイルまたはTestEnvSetupから有効なAPIキーが取得されることを確認
        final effectiveHotpepperKey =
            EnvironmentConfig.effectiveHotpepperApiKey;
        final effectiveGoogleMapsKey =
            EnvironmentConfig.effectiveGoogleMapsApiKey;

        expect(effectiveHotpepperKey, isNotEmpty,
            reason:
                'Effective HotPepper APIキーが空です。実際の値: "$effectiveHotpepperKey"');
        expect(effectiveGoogleMapsKey, isNotEmpty,
            reason:
                'Effective Google Maps APIキーが空です。実際の値: "$effectiveGoogleMapsKey"');
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
        // .env.testファイルからキーが読み込まれているので、マスクされた形式で表示される
        expect(debugInfo['hotpepperApiKey'], matches(r'^.{8}\.\.\.'));
        expect(debugInfo['googleMapsApiKey'], matches(r'^.{8}\.\.\.'));
        expect(debugInfo['hotpepperApiUrl'],
            'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
      });

      test('should mask API keys in debug info when available', () {
        final debugInfo = EnvironmentConfig.debugInfo;

        // Check that keys are either masked or marked as unset
        final hotpepperKey = debugInfo['hotpepperApiKey'] as String;
        final googleMapsKey = debugInfo['googleMapsApiKey'] as String;

        expect(
            hotpepperKey,
            anyOf(
              equals('(未設定)'),
              contains('...'), // Masked key format
            ));

        expect(
            googleMapsKey,
            anyOf(
              equals('(未設定)'),
              contains('...'), // Masked key format
            ));
      });
    });
  });
}
