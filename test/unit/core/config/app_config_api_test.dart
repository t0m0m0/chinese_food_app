import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('AppConfig API Configuration Tests', () {
    setUp(() {
      AppConfig.forceUninitialize();
    });

    tearDown(() {
      AppConfig.forceUninitialize();
    });

    test('should provide API configuration through AppConfig.api', () {
      // Act
      final apiConfig = AppConfig.api;

      // Assert
      expect(apiConfig, isA<ApiConfigAccessor>());
      expect(apiConfig.hotpepperApiUrl, isA<String>());
      expect(apiConfig.hotpepperApiTimeout, isA<int>());
    });

    test('should return debug information for API config', () {
      // Act
      final debugInfo = AppConfig.api.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
    });

    test('should handle HotPepper API key access correctly', () {
      // Act & Assert - 開発環境では同期版のキーアクセスが可能
      expect(() => AppConfig.api.hotpepperApiKey, returnsNormally);
    });

    test('should provide consistent API URL', () {
      // Act
      final apiUrl = AppConfig.api.hotpepperApiUrl;

      // Assert
      expect(apiUrl, isNotEmpty);
      expect(apiUrl, contains('hotpepper'));
    });

    test('should provide valid timeout configuration', () {
      // Act
      final timeout = AppConfig.api.hotpepperApiTimeout;

      // Assert
      expect(timeout, greaterThan(0));
      expect(timeout, lessThanOrEqualTo(60000)); // 60秒以下の合理的な値
    });
  });
}
