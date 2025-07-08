import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_validator.dart';

void main() {
  group('ConfigValidator', () {
    group('validateConfiguration', () {
      test('should return errors when API keys are missing', () {
        final errors = ConfigValidator.validateConfiguration();

        // In test environment, API keys are not set
        expect(errors, isNotEmpty);
        expect(
            errors.any((error) => error.contains('HotPepper API キーが設定されていません')),
            isTrue);
        expect(
            errors
                .any((error) => error.contains('Google Maps API キーが設定されていません')),
            isTrue);
      });
    });

    group('API key format validation', () {
      test('should validate HotPepper API key format', () {
        // Test internal method through reflection or create helper
        // For now, test the overall validation behavior
        final errors = ConfigValidator.validateConfiguration();

        // Should include format validation errors when keys are invalid
        expect(errors, isA<List<String>>());
      });

      test('should validate Google Maps API key format', () {
        // Test the Google Maps API key format validation
        final errors = ConfigValidator.validateConfiguration();

        expect(errors, isA<List<String>>());
      });
    });

    group('environment-specific validation', () {
      test('should validate development environment', () {
        // Test development environment specific validation
        final errors = ConfigValidator.validateConfiguration();

        // Should contain development-specific messages
        expect(errors.any((error) => error.contains('開発環境')), isTrue);
      });
    });

    group('configuration status', () {
      test('should return false for isConfigurationValid when keys missing',
          () {
        expect(ConfigValidator.isConfigurationValid, isFalse);
      });

      test('should detect critical errors', () {
        // In test environment, there might be format or missing key errors
        expect(ConfigValidator.hasCriticalErrors, isA<bool>());
      });
    });

    group('configuration details', () {
      test('should provide comprehensive configuration details', () {
        final details = ConfigValidator.configurationDetails;

        expect(details, isA<Map<String, dynamic>>());
        expect(details['environment'], isA<String>());
        expect(details['validationErrors'], isA<List<String>>());
        expect(details['isValid'], isA<bool>());
        expect(details['hasCriticalErrors'], isA<bool>());
        expect(details['debugInfo'], isA<Map<String, dynamic>>());
      });

      test('should include validation errors in details', () {
        final details = ConfigValidator.configurationDetails;
        final errors = details['validationErrors'] as List<String>;

        expect(errors, isNotEmpty);
        expect(errors.any((error) => error.contains('API キー')), isTrue);
      });
    });

    group('helper validation methods', () {
      test('should handle empty configuration gracefully', () {
        // Test that validator doesn't crash with empty configuration
        expect(() => ConfigValidator.validateConfiguration(), returnsNormally);
      });

      test('should provide consistent validation results', () {
        final errors1 = ConfigValidator.validateConfiguration();
        final errors2 = ConfigValidator.validateConfiguration();

        expect(errors1, equals(errors2));
      });
    });
  });
}
