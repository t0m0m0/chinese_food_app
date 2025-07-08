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
      test('should return empty strings when environment variables not set',
          () {
        expect(EnvironmentConfig.hotpepperApiKey, isEmpty);
        expect(EnvironmentConfig.googleMapsApiKey, isEmpty);
        expect(EnvironmentConfig.fallbackHotpepperApiKey, isEmpty);
        expect(EnvironmentConfig.fallbackGoogleMapsApiKey, isEmpty);
      });

      test('should use effective API keys with fallback logic', () {
        // When both environment-specific and fallback keys are empty
        expect(EnvironmentConfig.effectiveHotpepperApiKey, isEmpty);
        expect(EnvironmentConfig.effectiveGoogleMapsApiKey, isEmpty);
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
        expect(debugInfo['hotpepperApiKey'], '(未設定)');
        expect(debugInfo['googleMapsApiKey'], '(未設定)');
        expect(debugInfo['hotpepperApiUrl'],
            'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
      });

      test('should mask API keys in debug info when available', () {
        // This test assumes we can't actually set environment variables in tests
        // but verifies the masking logic structure
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
