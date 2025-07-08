import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';

void main() {
  group('ConfigManager', () {
    setUp(() {
      // Reset ConfigManager state before each test
      ConfigManager.forceInitialize();
    });

    group('initialization', () {
      test('should not be initialized by default', () {
        expect(ConfigManager.isInitialized, isFalse);
      });

      test('should initialize successfully with throwOnValidationError false',
          () async {
        await ConfigManager.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );

        expect(ConfigManager.isInitialized, isTrue);
      });

      test('should throw StateError when accessing uninitialized manager', () {
        expect(() => ConfigManager.environment, throwsStateError);
        expect(() => ConfigManager.hotpepperApiKey, throwsStateError);
        expect(() => ConfigManager.googleMapsApiKey, throwsStateError);
      });

      test('should provide debug string for uninitialized state', () {
        final debugString = ConfigManager.debugString;
        expect(debugString, contains('未初期化'));
      });
    });

    group('after initialization', () {
      setUp(() async {
        await ConfigManager.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );
      });

      test('should provide access to configuration values', () {
        expect(ConfigManager.environment, isA<Environment>());
        expect(ConfigManager.hotpepperApiKey, isA<String>());
        expect(ConfigManager.googleMapsApiKey, isA<String>());
        expect(ConfigManager.hotpepperApiUrl, isA<String>());
      });

      test('should provide environment flags', () {
        expect(ConfigManager.isDevelopment, isA<bool>());
        expect(ConfigManager.isStaging, isA<bool>());
        expect(ConfigManager.isProduction, isA<bool>());
      });

      test('should provide validation methods', () {
        expect(ConfigManager.isConfigurationValid, isA<bool>());
        expect(ConfigManager.hasCriticalErrors, isA<bool>());
        expect(ConfigManager.hasValidApiKeys, isA<bool>());
      });

      test('should validate configuration', () {
        final errors = ConfigManager.validateConfiguration();
        expect(errors, isA<List<String>>());
      });

      test('should provide debug information', () {
        final debugInfo = ConfigManager.debugInfo;
        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo['environment'], isA<String>());
        expect(debugInfo['hotpepperApiKey'], isA<String>());
        expect(debugInfo['googleMapsApiKey'], isA<String>());
      });

      test('should provide debug string', () {
        final debugString = ConfigManager.debugString;
        expect(debugString, contains('ConfigManager 設定情報'));
        expect(debugString, contains('環境:'));
      });

      test('should support generic getValue and setValue', () {
        // Test getting existing value
        final environment =
            ConfigManager.getValue<String>('environment', 'unknown');
        expect(environment, isA<String>());

        // Test getting non-existent value with default
        final customValue = ConfigManager.getValue<int>('customKey', 42);
        expect(customValue, 42);

        // Test setting and getting custom value
        ConfigManager.setValue('testKey', 'testValue');
        final retrievedValue = ConfigManager.getValue<String>('testKey', '');
        expect(retrievedValue, 'testValue');
      });
    });

    group('error handling', () {
      test(
          'should handle validation errors gracefully when throwOnValidationError is false',
          () async {
        expect(
            () async => await ConfigManager.initialize(
                  throwOnValidationError: false,
                  enableDebugLogging: false,
                ),
            returnsNormally);
      });

      test('should provide consistent state after initialization', () async {
        await ConfigManager.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );

        // Multiple calls should return consistent results
        expect(ConfigManager.environment, ConfigManager.environment);
        expect(ConfigManager.isConfigurationValid,
            ConfigManager.isConfigurationValid);
      });
    });

    group('URL and key access', () {
      setUp(() async {
        await ConfigManager.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );
      });

      test('should provide HotPepper API URL', () {
        final url = ConfigManager.hotpepperApiUrl;
        expect(url, 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
      });

      test('should handle empty API keys gracefully', () {
        // In test environment, keys are typically empty
        expect(ConfigManager.hotpepperApiKey, isA<String>());
        expect(ConfigManager.googleMapsApiKey, isA<String>());
      });
    });
  });
}
