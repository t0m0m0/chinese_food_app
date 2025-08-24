import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_validator.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../helpers/test_env_setup.dart';

/// APIキー長さテスト用のデータクラス
class _ApiKeyTestCase {
  const _ApiKeyTestCase(this.apiKey, this.expectedErrorType, this.description);

  final String apiKey;
  final String expectedErrorType;
  final String description;
}

/// APIキー文字セットテスト用のデータクラス
class _CharacterTestCase {
  const _CharacterTestCase(this.apiKey, this.shouldBeValid, this.description);

  final String apiKey;
  final bool shouldBeValid;
  final String description;
}

/// APIキー検証結果をアサートするヘルパー関数
void _assertApiKeyValidationResult(
    List<String> errors, _ApiKeyTestCase testCase) {
  if (testCase.expectedErrorType.isEmpty) {
    // エラーがないことを期待
    final hasApiKeyErrors = errors.any((error) =>
        error.contains('HOTPEPPER_API_KEY') ||
        error.contains('HotPepper API キーの形式が無効'));
    expect(hasApiKeyErrors, isFalse, reason: testCase.description);
  } else if (testCase.expectedErrorType == '設定されていません') {
    // APIキー未設定エラーを期待
    final hasMissingError = errors.any((error) =>
        error.contains('HOTPEPPER_API_KEY') && error.contains('が設定されていません'));
    expect(hasMissingError, isTrue, reason: testCase.description);
  } else if (testCase.expectedErrorType == '形式が無効') {
    // APIキー形式エラーを期待
    final hasFormatError =
        errors.any((error) => error.contains('HotPepper API キーの形式が無効です'));
    expect(hasFormatError, isTrue, reason: testCase.description);
  }
}

void main() {
  group('Production API Key Validation', () {
    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    setUp(() async {
      // 各テスト前にクリーンな状態に戻す
      EnvironmentConfig.resetForTesting();
      // dotenv.clean() の代わりに、既存の設定をクリア
      try {
        dotenv.env.clear();
      } catch (e) {
        // dotenv が未初期化の場合は何もしない
      }
    });

    tearDown(() async {
      // テスト後のクリーンアップ
      EnvironmentConfig.clearTestContext();
      EnvironmentConfig.resetForTesting();
      // テスト環境を元に戻す
      await TestEnvSetup.initializeTestEnvironment();
    });

    group('Production Environment API Key Validation', () {
      test(
          'should fail validation when production environment has empty HotPepper API key',
          () async {
        // Arrange: 本番環境でAPIキーが空の状態を設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=
''');

        await EnvironmentConfig.initialize();

        // Act: バリデーション実行
        final errors = ConfigValidator.validateConfiguration();

        // Assert: 本番環境でAPIキーが空の場合はエラーが発生すること
        expect(
            errors.any((error) =>
                error.contains('production環境') &&
                error.contains('HOTPEPPER_API_KEY') &&
                error.contains('が設定されていません')),
            isTrue,
            reason: 'Production environment should require HotPepper API key');
      });

      test(
          'should fail validation when production HotPepper API key is too short',
          () async {
        // Arrange: 本番環境で短いAPIキーを設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=short123
''');

        await EnvironmentConfig.initialize();

        // Act: バリデーション実行
        final errors = ConfigValidator.validateConfiguration();

        // Assert: 短いAPIキーの場合は形式エラーが発生すること
        expect(
            errors.any((error) => error.contains('HotPepper API キーの形式が無効です')),
            isTrue,
            reason: 'Short API key should fail format validation');
      });

      test(
          'should fail validation when production HotPepper API key contains invalid characters',
          () async {
        // Arrange: 本番環境で無効な文字を含むAPIキーを設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=invalid-key-with-special-chars!@#
''');

        await EnvironmentConfig.initialize();

        // Act: バリデーション実行
        final errors = ConfigValidator.validateConfiguration();

        // Assert: 無効な文字を含むAPIキーの場合は形式エラーが発生すること
        expect(
            errors.any((error) => error.contains('HotPepper API キーの形式が無効です')),
            isTrue,
            reason: 'API key with invalid characters should fail validation');
      });

      test('should pass validation when production HotPepper API key is valid',
          () async {
        // Arrange: 本番環境で有効なAPIキーを設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=validproductionapikey123456789
''');

        await EnvironmentConfig.initialize();

        // Act: バリデーション実行
        final errors = ConfigValidator.validateConfiguration();

        // Assert: 有効なAPIキーの場合はAPIキー関連のエラーは発生しないこと
        expect(
            errors.where((error) =>
                error.contains('HOTPEPPER_API_KEY') ||
                error.contains('HotPepper API キーの形式が無効')),
            isEmpty,
            reason: 'Valid production API key should pass validation');
      });
    });

    group('Production Environment Security Validation', () {
      test(
          'should identify production environment as having critical errors when API key is missing',
          () async {
        // Arrange: 本番環境でAPIキーが空の状態を設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=
''');

        await EnvironmentConfig.initialize();

        // Act & Assert: 本番環境でAPIキーが空の場合はクリティカルエラーとして扱われること
        expect(ConfigValidator.hasCriticalErrors, isTrue,
            reason: 'Missing API key in production should be a critical error');
      });

      test(
          'should not have critical errors when all production requirements are met',
          () async {
        // Arrange: 本番環境で全ての要件を満たす設定
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=validproductionapikey123456789
''');

        await EnvironmentConfig.initialize();

        // Act & Assert: 全ての要件を満たす場合はクリティカルエラーはないこと
        final errors = ConfigValidator.validateConfiguration();
        final hasCriticalProductionErrors = errors.any((error) =>
            error.contains('production環境') || error.contains('形式が無効'));

        expect(hasCriticalProductionErrors, isFalse,
            reason:
                'Valid production configuration should not have critical errors');
      });
    });

    group('Production API Key Format Validation', () {
      // パラメータ化テスト用のデータ定義
      final lengthTestCases = [
        // 空のAPIキーの場合は「設定されていません」エラーになる
        const _ApiKeyTestCase(
            '', '設定されていません', 'Empty key should show missing error'),
        // 短いAPIキーの場合は「形式が無効」エラーになる
        const _ApiKeyTestCase(
            'short', '形式が無効', '5 chars should show format error'),
        // 有効なAPIキーの場合はエラーなし（正確に16文字）
        const _ApiKeyTestCase(
            'mediumkey1234567', '', '16 chars should be valid'),
        const _ApiKeyTestCase('verylongvalidproductionapikey1234567890', '',
            '39+ chars should be valid'),
      ];

      for (final testCase in lengthTestCases) {
        test('should validate API key length: ${testCase.description}',
            () async {
          // Arrange
          dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=${testCase.apiKey}
''');

          await EnvironmentConfig.initialize();

          // Act
          final errors = ConfigValidator.validateConfiguration();

          // Assert
          _assertApiKeyValidationResult(errors, testCase);
        });
      }

      // パラメータ化テスト用のデータ定義
      final characterTestCases = [
        const _CharacterTestCase(
            'validkey123456789', true, 'Alphanumeric key should be valid'),
        const _CharacterTestCase('VALIDKEY123456789', true,
            'Uppercase alphanumeric should be valid'),
        const _CharacterTestCase('ValidKey123456789', true,
            'Mixed case alphanumeric should be valid'),
        const _CharacterTestCase(
            'invalid-key-123456', false, 'Key with hyphens should be invalid'),
        const _CharacterTestCase('invalid_key_123456', false,
            'Key with underscores should be invalid'),
        const _CharacterTestCase('invalidkey123456!', false,
            'Key with special chars should be invalid'),
        const _CharacterTestCase(
            'invalidkey 123456', false, 'Key with spaces should be invalid'),
      ];

      for (final testCase in characterTestCases) {
        test('should validate API key characters: ${testCase.description}',
            () async {
          // Arrange
          dotenv.testLoad(fileInput: '''
FLUTTER_ENV=production
HOTPEPPER_API_KEY=${testCase.apiKey}
''');

          await EnvironmentConfig.initialize();

          // Act
          final errors = ConfigValidator.validateConfiguration();
          final hasFormatError =
              errors.any((error) => error.contains('HotPepper API キーの形式が無効です'));

          // Assert
          expect(hasFormatError, !testCase.shouldBeValid,
              reason: testCase.description);
        });
      }
    });
  });
}
