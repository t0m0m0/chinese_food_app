import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chinese_food_app/core/config/location_config.dart';

void main() {
  group('LocationConfig Tests', () {
    test('should have correct default values', () {
      expect(LocationConfig.defaultTimeoutSeconds, 10);
      expect(LocationConfig.maxTimeoutSeconds, 60);
      expect(LocationConfig.minTimeoutSeconds, 1);
      expect(LocationConfig.defaultAccuracy, LocationAccuracy.high);
      expect(LocationConfig.fallbackAccuracy, LocationAccuracy.medium);
      expect(LocationConfig.defaultLocationRadius, 1000.0);
      expect(LocationConfig.minLocationRadius, 100.0);
      expect(LocationConfig.maxLocationRadius, 10000.0);
      expect(LocationConfig.minAcceptableAccuracy, 100.0);
      expect(LocationConfig.maxAcceptableAccuracy, 1000.0);
      expect(LocationConfig.locationUpdateInterval, 30);
      expect(LocationConfig.minUpdateInterval, 5);
      expect(LocationConfig.maxUpdateInterval, 300);
    });

    test('should validate timeout values correctly', () {
      expect(LocationConfig.isValidTimeout(1), true);
      expect(LocationConfig.isValidTimeout(30), true);
      expect(LocationConfig.isValidTimeout(60), true);
      expect(LocationConfig.isValidTimeout(0), false);
      expect(LocationConfig.isValidTimeout(-1), false);
      expect(LocationConfig.isValidTimeout(61), false);
    });

    test('should validate radius values correctly', () {
      expect(LocationConfig.isValidRadius(100.0), true);
      expect(LocationConfig.isValidRadius(1000.0), true);
      expect(LocationConfig.isValidRadius(10000.0), true);
      expect(LocationConfig.isValidRadius(99.9), false);
      expect(LocationConfig.isValidRadius(-1.0), false);
      expect(LocationConfig.isValidRadius(10000.1), false);
    });

    test('should validate accuracy values correctly', () {
      expect(LocationConfig.isValidAccuracy(100.0), true);
      expect(LocationConfig.isValidAccuracy(500.0), true);
      expect(LocationConfig.isValidAccuracy(1000.0), true);
      expect(LocationConfig.isValidAccuracy(99.9), false);
      expect(LocationConfig.isValidAccuracy(-1.0), false);
      expect(LocationConfig.isValidAccuracy(1000.1), false);
    });

    test('should validate update interval values correctly', () {
      expect(LocationConfig.isValidUpdateInterval(5), true);
      expect(LocationConfig.isValidUpdateInterval(30), true);
      expect(LocationConfig.isValidUpdateInterval(300), true);
      expect(LocationConfig.isValidUpdateInterval(4), false);
      expect(LocationConfig.isValidUpdateInterval(-1), false);
      expect(LocationConfig.isValidUpdateInterval(301), false);
    });

    test('should validate acceptable permissions correctly', () {
      expect(
          LocationConfig.isPermissionAcceptable(LocationPermission.whileInUse),
          true);
      expect(LocationConfig.isPermissionAcceptable(LocationPermission.always),
          true);
      expect(LocationConfig.isPermissionAcceptable(LocationPermission.denied),
          false);
      expect(
          LocationConfig.isPermissionAcceptable(
              LocationPermission.deniedForever),
          false);
      expect(
          LocationConfig.isPermissionAcceptable(
              LocationPermission.unableToDetermine),
          false);
    });

    test('should get correct accuracy level from string', () {
      expect(
          LocationConfig.getAccuracyLevel('lowest'), LocationAccuracy.lowest);
      expect(LocationConfig.getAccuracyLevel('low'), LocationAccuracy.low);
      expect(
          LocationConfig.getAccuracyLevel('medium'), LocationAccuracy.medium);
      expect(LocationConfig.getAccuracyLevel('high'), LocationAccuracy.high);
      expect(LocationConfig.getAccuracyLevel('best'), LocationAccuracy.best);
      expect(LocationConfig.getAccuracyLevel('bestfornavigation'),
          LocationAccuracy.bestForNavigation);
      expect(LocationConfig.getAccuracyLevel('invalid'),
          LocationConfig.defaultAccuracy);
      expect(
          LocationConfig.getAccuracyLevel(''), LocationConfig.defaultAccuracy);
    });

    test('should provide comprehensive debug info', () {
      final debugInfo = LocationConfig.debugInfo;

      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo['defaultTimeoutSeconds'], isA<int>());
      expect(debugInfo['maxTimeoutSeconds'], isA<int>());
      expect(debugInfo['minTimeoutSeconds'], isA<int>());
      expect(debugInfo['defaultAccuracy'], isA<String>());
      expect(debugInfo['fallbackAccuracy'], isA<String>());
      expect(debugInfo['acceptablePermissions'], isA<List>());
      expect(debugInfo['defaultLocationRadius'], isA<double>());
      expect(debugInfo['minLocationRadius'], isA<double>());
      expect(debugInfo['maxLocationRadius'], isA<double>());
      expect(debugInfo['minAcceptableAccuracy'], isA<double>());
      expect(debugInfo['maxAcceptableAccuracy'], isA<double>());
      expect(debugInfo['locationUpdateInterval'], isA<int>());
      expect(debugInfo['minUpdateInterval'], isA<int>());
      expect(debugInfo['maxUpdateInterval'], isA<int>());
    });

    test('should have acceptable permissions list', () {
      final acceptablePermissions = LocationConfig.acceptablePermissions;

      expect(acceptablePermissions, contains(LocationPermission.whileInUse));
      expect(acceptablePermissions, contains(LocationPermission.always));
      expect(acceptablePermissions, isNot(contains(LocationPermission.denied)));
      expect(acceptablePermissions,
          isNot(contains(LocationPermission.deniedForever)));
      expect(acceptablePermissions,
          isNot(contains(LocationPermission.unableToDetermine)));
    });

    test('should validate boundary values correctly', () {
      // Timeout boundary tests
      expect(LocationConfig.isValidTimeout(1), true); // min
      expect(LocationConfig.isValidTimeout(60), true); // max
      expect(LocationConfig.isValidTimeout(0), false); // below min
      expect(LocationConfig.isValidTimeout(61), false); // above max

      // Radius boundary tests
      expect(LocationConfig.isValidRadius(100.0), true); // min
      expect(LocationConfig.isValidRadius(10000.0), true); // max
      expect(LocationConfig.isValidRadius(99.9), false); // below min
      expect(LocationConfig.isValidRadius(10000.1), false); // above max

      // Update interval boundary tests
      expect(LocationConfig.isValidUpdateInterval(5), true); // min
      expect(LocationConfig.isValidUpdateInterval(300), true); // max
      expect(LocationConfig.isValidUpdateInterval(4), false); // below min
      expect(LocationConfig.isValidUpdateInterval(301), false); // above max
    });
  });
}
