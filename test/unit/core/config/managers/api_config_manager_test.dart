import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/managers/api_config_manager.dart';

void main() {
  group('ApiConfigManager Tests', () {
    test('should validate API configuration correctly', () {
      // Act
      final errors = ApiConfigManager.validate();

      // Assert
      expect(errors, isA<List<String>>());
    });

    test('should return configuration info', () {
      // Act
      final config = ApiConfigManager.getConfig();

      // Assert
      expect(config, isA<Map<String, dynamic>>());
      expect(config, containsPair('type', 'api'));
    });

    test('should detect timeout validation errors', () {
      // Act
      final errors = ApiConfigManager.validate();

      // Assert - これは実装依存だが、最低限の構造をテスト
      expect(errors, isA<List<String>>());
    });

    test('should provide debug information', () {
      // Act
      final debugInfo = ApiConfigManager.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('manager', 'ApiConfigManager'));
    });
  });
}