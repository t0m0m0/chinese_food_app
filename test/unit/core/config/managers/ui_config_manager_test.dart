import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/managers/ui_config_manager.dart';

void main() {
  group('UiConfigManager Tests', () {
    test('should validate UI configuration correctly', () {
      // Act
      final errors = UiConfigManager.validate();

      // Assert
      expect(errors, isA<List<String>>());
    });

    test('should return UI configuration info', () {
      // Act
      final config = UiConfigManager.getConfig();

      // Assert
      expect(config, isA<Map<String, dynamic>>());
      expect(config, containsPair('type', 'ui'));
      expect(config.containsKey('padding'), isTrue);
      expect(config.containsKey('borderRadius'), isTrue);
      expect(config.containsKey('mapZoom'), isTrue);
    });

    test('should provide debug information', () {
      // Act
      final debugInfo = UiConfigManager.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('manager', 'UiConfigManager'));
      expect(debugInfo.containsKey('config'), isTrue);
      expect(debugInfo.containsKey('validationErrors'), isTrue);
    });
  });
}