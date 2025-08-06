import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/managers/location_config_manager.dart';

void main() {
  group('LocationConfigManager Tests', () {
    test('should validate location configuration correctly', () {
      // Act
      final errors = LocationConfigManager.validate();

      // Assert
      expect(errors, isA<List<String>>());
    });

    test('should return location configuration info', () {
      // Act
      final config = LocationConfigManager.getConfig();

      // Assert
      expect(config, isA<Map<String, dynamic>>());
      expect(config, containsPair('type', 'location'));
      expect(config.containsKey('timeout'), isTrue);
      expect(config.containsKey('radius'), isTrue);
      expect(config.containsKey('updateInterval'), isTrue);
    });

    test('should provide debug information', () {
      // Act
      final debugInfo = LocationConfigManager.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('manager', 'LocationConfigManager'));
      expect(debugInfo.containsKey('config'), isTrue);
      expect(debugInfo.containsKey('validationErrors'), isTrue);
    });
  });
}