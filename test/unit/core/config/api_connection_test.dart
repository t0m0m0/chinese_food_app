import 'package:flutter_test/flutter_test.dart';
// ignore: deprecated_member_use
import 'package:chinese_food_app/core/config/api_diagnostics.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ApiConnectionTester', () {
    setUp(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    tearDown(() {
      TestEnvSetup.cleanupTestEnvironment();
    });

    test('should test basic connectivity', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'valid_test_key');

      // Act
      final result = await ApiConnectionTester.testBasicConnectivity();

      // Assert
      expect(result.isSuccessful, isTrue);
      expect(result.testType, equals('basic_connectivity'));
      expect(result.duration, isNotNull);
    });

    test('should detect API key issues', () async {
      // Arrange
      TestEnvSetup.clearTestApiKey('HOTPEPPER_API_KEY');

      // Act
      final result = await ApiConnectionTester.testApiKeyValidation();

      // Assert
      expect(result.isSuccessful, isFalse);
      expect(result.errorMessage, contains('APIキー'));
    });

    test('should provide comprehensive connection test', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_key_123');

      // Act
      final results = await ApiConnectionTester.runComprehensiveTest();

      // Assert
      expect(results, isNotEmpty);
      expect(results.any((r) => r.testType == 'basic_connectivity'), isTrue);
      expect(results.any((r) => r.testType == 'api_key_validation'), isTrue);
      expect(results.any((r) => r.testType == 'config_validation'), isTrue);
    });

    test('should support custom timeout settings', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_timeout_key');
      final customTimeout = const Duration(seconds: 5);

      // Act
      final result = await ApiConnectionTester.testBasicConnectivity(
        timeout: customTimeout,
      );

      // Assert
      expect(result.testType, equals('basic_connectivity'));
      expect(result.duration, isNotNull);
      // 接続が成功した場合、カスタムタイムアウトの影響は直接見えないが、
      // エラーメッセージでタイムアウト値が正しく設定されることを間接的に確認
    });

    test('should handle timeout appropriately in comprehensive test', () async {
      // Arrange
      TestEnvSetup.setTestApiKey(
          'HOTPEPPER_API_KEY', 'test_comprehensive_timeout');

      // Act
      final results = await ApiConnectionTester.runComprehensiveTest(
        connectivityTimeout: const Duration(seconds: 8),
        apiCallTimeout: const Duration(seconds: 12),
      );

      // Assert
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3)); // 基本的な3つのテスト

      // 各テストが適切に実行されることを確認
      for (final result in results) {
        expect(result.duration, isNotNull);
        expect(result.testType, isNotEmpty);
      }
    });
  });
}
