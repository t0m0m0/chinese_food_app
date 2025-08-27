import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/operations_config.dart';

void main() {
  group('OperationsConfig', () {
    test('should have valid support contact email', () {
      expect(OperationsConfig.supportEmail, isNotEmpty);
      expect(OperationsConfig.supportEmail, contains('@'));
    });

    test('should have valid response time limits', () {
      expect(OperationsConfig.supportResponseTimeHours, greaterThan(0));
      expect(OperationsConfig.supportResponseTimeHours, lessThanOrEqualTo(24));
    });

    test('should have valid crash rate threshold', () {
      expect(OperationsConfig.crashRateThreshold, greaterThan(0));
      expect(OperationsConfig.crashRateThreshold, lessThanOrEqualTo(1.0));
    });

    test('should have valid app store rating threshold', () {
      expect(OperationsConfig.appStoreRatingThreshold, greaterThan(0));
      expect(OperationsConfig.appStoreRatingThreshold, lessThanOrEqualTo(5.0));
    });

    test('should have valid KPI monitoring intervals', () {
      expect(
          OperationsConfig.dailyAnalyticsUpdateHour, greaterThanOrEqualTo(0));
      expect(OperationsConfig.dailyAnalyticsUpdateHour, lessThan(24));
      expect(OperationsConfig.weeklyReportDayOfWeek, greaterThanOrEqualTo(1));
      expect(OperationsConfig.weeklyReportDayOfWeek, lessThanOrEqualTo(7));
    });

    test('should have valid help content configuration', () {
      expect(OperationsConfig.helpSectionsEnabled, isA<Map<String, bool>>());
      expect(OperationsConfig.helpSectionsEnabled, isNotEmpty);
      expect(OperationsConfig.helpSectionsEnabled['faq'], isNotNull);
      expect(OperationsConfig.helpSectionsEnabled['tutorial'], isNotNull);
      expect(OperationsConfig.helpSectionsEnabled['contact'], isNotNull);
    });

    test('should validate email format', () {
      expect(OperationsConfig.isValidEmailFormat(OperationsConfig.supportEmail),
          isTrue);
      expect(OperationsConfig.isValidEmailFormat('invalid-email'), isFalse);
      expect(OperationsConfig.isValidEmailFormat('test@example.com'), isTrue);
      expect(OperationsConfig.isValidEmailFormat(''), isFalse);
    });

    test('should validate crash rate threshold', () {
      expect(OperationsConfig.isValidCrashRate(0.001), isTrue);
      expect(OperationsConfig.isValidCrashRate(0.1), isTrue);
      expect(OperationsConfig.isValidCrashRate(1.0), isTrue);
      expect(OperationsConfig.isValidCrashRate(1.1), isFalse);
      expect(OperationsConfig.isValidCrashRate(-0.1), isFalse);
    });

    test('should validate app store rating threshold', () {
      expect(OperationsConfig.isValidRatingThreshold(4.0), isTrue);
      expect(OperationsConfig.isValidRatingThreshold(3.5), isTrue);
      expect(OperationsConfig.isValidRatingThreshold(5.0), isTrue);
      expect(OperationsConfig.isValidRatingThreshold(5.1), isFalse);
      expect(OperationsConfig.isValidRatingThreshold(0.0), isFalse);
    });

    test('should have debug info', () {
      final debugInfo = OperationsConfig.debugInfo;
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, isNotEmpty);
      expect(debugInfo['supportEmail'], equals(OperationsConfig.supportEmail));
      expect(debugInfo['crashRateThreshold'],
          equals(OperationsConfig.crashRateThreshold));
      expect(debugInfo['appStoreRatingThreshold'],
          equals(OperationsConfig.appStoreRatingThreshold));
    });
  });
}
