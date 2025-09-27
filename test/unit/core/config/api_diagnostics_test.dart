import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/api_diagnostics.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ApiDiagnostics', () {
    setUp(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    tearDown(() {
      TestEnvSetup.cleanupTestEnvironment();
    });

    test('should provide comprehensive API configuration status', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_key_123');

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.isConfigValid, isTrue);
      expect(diagnostics.hotpepperApiKeyStatus, equals('available'));
      expect(diagnostics.initializationStatus, equals('initialized'));
      expect(diagnostics.securityMode, equals('legacy'));
    });

    test('should detect missing API key', () async {
      // Arrange
      TestEnvSetup.clearTestApiKey('HOTPEPPER_API_KEY');

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.isConfigValid, isFalse);
      expect(diagnostics.hotpepperApiKeyStatus, equals('missing'));
      expect(diagnostics.issues, contains('HotPepper APIキーが設定されていません'));
    });

    test('should provide detailed configuration info', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'valid_key');

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.environment, isNotEmpty);
      expect(diagnostics.timestamp, isNotNull);
      expect(diagnostics.suggestions, isNotEmpty);
    });
  });
}
