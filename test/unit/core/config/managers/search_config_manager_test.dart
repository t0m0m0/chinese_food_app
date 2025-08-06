import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/managers/search_config_manager.dart';

void main() {
  group('SearchConfigManager Tests', () {
    test('should validate search configuration correctly', () {
      // Act
      final errors = SearchConfigManager.validate();

      // Assert
      expect(errors, isA<List<String>>());
    });

    test('should return search configuration info', () {
      // Act
      final config = SearchConfigManager.getConfig();

      // Assert
      expect(config, isA<Map<String, dynamic>>());
      expect(config, containsPair('type', 'search'));
      expect(config.containsKey('range'), isTrue);
      expect(config.containsKey('count'), isTrue);
      expect(config.containsKey('keyword'), isTrue);
    });

    test('should provide debug information', () {
      // Act
      final debugInfo = SearchConfigManager.debugInfo;

      // Assert
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('manager', 'SearchConfigManager'));
      expect(debugInfo.containsKey('config'), isTrue);
      expect(debugInfo.containsKey('validationErrors'), isTrue);
    });
  });
}
