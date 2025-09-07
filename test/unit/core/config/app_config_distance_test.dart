import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('AppConfig Distance Management Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // SharedPreferencesのモック設定
      SharedPreferences.setMockInitialValues({});

      // SystemChannelsのモック設定
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        return null;
      });
    });

    tearDown(() {
      AppConfig.forceUninitialize();
    });

    test('should save distance using AppConfig.search.saveDistance', () async {
      // Arrange
      const testDistance = 3;

      // Act
      await AppConfig.search.saveDistance(testDistance);

      // Assert - 例外が発生しないことを確認
      expect(true, isTrue);
    });

    test('should get distance using AppConfig.search.getDistance', () async {
      // Act
      final distance = await AppConfig.search.getDistance();

      // Assert - デフォルト値が返されることを確認
      expect(distance, isA<int>());
    });

    test('should get default distance when no saved distance exists', () async {
      // Act
      final distance = await AppConfig.search.getDistance();

      // Assert - デフォルト値（3 = 1000m）が返されることを確認
      expect(distance, equals(3)); // SearchConfig.defaultRange
    });

    test('should save and retrieve distance correctly', () async {
      // Arrange
      const testDistance = 2;

      // Act
      await AppConfig.search.saveDistance(testDistance);
      final retrievedDistance = await AppConfig.search.getDistance();

      // Assert
      expect(retrievedDistance, equals(testDistance));
    });

    test('should validate distance range when saving', () async {
      // Arrange
      const invalidDistance = 6; // SearchConfig.rangeOptionsの範囲外

      // Act & Assert - ArgumentErrorが発生することを確認
      expect(() => AppConfig.search.saveDistance(invalidDistance),
          throwsArgumentError);
    });

    test('should get distance in meters correctly', () async {
      // Arrange
      const testRange = 4; // 2000m
      await AppConfig.search.saveDistance(testRange);

      // Act
      final distanceInMeters = await AppConfig.search.getDistanceInMeters();

      // Assert
      expect(distanceInMeters, equals(2000));
    });
  });
}
