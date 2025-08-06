import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/managers/database_config_manager.dart';

void main() {
  group('DatabaseConfigManager Tests', () {
    test('should validate database configuration correctly', () {
      // Act
      final errors = DatabaseConfigManager.validate();

      // Assert
      expect(errors, isA<List<String>>());
    });

    test('should return database configuration info', () {
      // Act
      final config = DatabaseConfigManager.getConfig();

      // Assert
      expect(config, isA<Map<String, dynamic>>());
      expect(config, containsPair('type', 'database'));
      expect(config.containsKey('databaseVersion'), isTrue);
      expect(config.containsKey('cacheSize'), isTrue);
      expect(config.containsKey('pageSize'), isTrue);
    });

    test('should provide debug information', () {
      // Act
      final debugInfo = DatabaseConfigManager.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('manager', 'DatabaseConfigManager'));
      expect(debugInfo.containsKey('config'), isTrue);
      expect(debugInfo.containsKey('validationErrors'), isTrue);
    });
  });
}
