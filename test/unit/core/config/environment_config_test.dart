import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';

void main() {
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
      test('should return API keys from .env file when available', () async {
        await EnvironmentConfig.initialize();
        // .envファイルからAPIキーが読み込まれることを確認
        expect(EnvironmentConfig.hotpepperApiKey, isNotEmpty);
        expect(EnvironmentConfig.googleMapsApiKey, isNotEmpty);
      });

      test('should use effective API keys', () async {
        // .envファイルから有効なAPIキーが取得されることを確認
        await EnvironmentConfig.initialize();
        expect(EnvironmentConfig.effectiveHotpepperApiKey, isNotEmpty);
        expect(EnvironmentConfig.effectiveGoogleMapsApiKey, isNotEmpty);
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
      test('should provide debug information', () async {
        await EnvironmentConfig.initialize();
        final debugInfo = EnvironmentConfig.debugInfo;

        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo['environment'], 'development');
        // .envファイルからキーが読み込まれているので、マスクされた形式で表示される
        expect(debugInfo['hotpepperApiKey'], matches(r'^.{8}\.\.\.'));
        expect(debugInfo['googleMapsApiKey'], matches(r'^.{8}\.\.\.'));
        expect(debugInfo['hotpepperApiUrl'],
            'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
      });

      test('should mask API keys in debug info when available', () async {
        // This test assumes we can't actually set environment variables in tests
        // but verifies the masking logic structure
        await EnvironmentConfig.initialize();
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
