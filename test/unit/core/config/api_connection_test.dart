import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/api_connection_tester.dart';
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
  });
}
