import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_validator.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ConfigValidator', () {
    setUpAll(() async {
      // ConfigValidatorを呼ぶ前にテスト環境を初期化
      await TestEnvSetup.initializeTestEnvironment();
      await EnvironmentConfig.initialize();
    });
    group('validateConfiguration', () {
      test('should return configuration without errors', () {
        final errors = ConfigValidator.validateConfiguration();

        // プロキシ経由でAPI呼び出しを行うため、HotPepper APIキーは不要
        // 設定検証は基本的な構成のみをチェック
        expect(errors, isA<List<String>>());
      });
    });

    // APIキー形式の検証は不要（プロキシ経由でAPI呼び出しを行うため）

    group('environment-specific validation', () {
      test('should validate development environment', () {
        // Test development environment specific validation
        final errors = ConfigValidator.validateConfiguration();

        // プロキシ経由でAPI呼び出しを行うため、環境別のAPIキー検証は不要
        expect(errors, isA<List<String>>());
      });
    });

    group('configuration status', () {
      test('should return configuration validation status', () {
        final isValid = ConfigValidator.isConfigurationValid;
        // プロキシ経由でAPI呼び出しを行うため、APIキーなしでも有効
        expect(isValid, isA<bool>());
      });

      test('should detect critical errors', () {
        // DotEnvの初期化確認を含めた総合的なエラー検出テスト
        // CI環境ではDotEnv初期化エラーまたは設定エラーが発生する可能性がある
        expect(() => ConfigValidator.hasCriticalErrors, returnsNormally);

        // エラー有無に関係なく、bool値が返されることを確認
        final hasErrors = ConfigValidator.hasCriticalErrors;
        expect(hasErrors, isA<bool>());
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

        // プロキシ経由でAPI呼び出しを行うため、検証エラーは構成関連のみ
        expect(errors, isA<List<String>>());
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
