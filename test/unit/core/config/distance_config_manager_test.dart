import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/core/config/distance_config_manager.dart';
import 'package:chinese_food_app/core/config/search_config.dart';

/// 距離設定管理サービスの単体テスト（TDD）
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// 距離設定の永続化と取得機能をテスト

void main() {
  group('DistanceConfigManager', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('saveDistance', () {
      test('有効な距離範囲を保存できる', () async {
        // Arrange
        const validRange = 3; // 1000m

        // Act
        await DistanceConfigManager.saveDistance(validRange);

        // Assert
        final savedRange = await DistanceConfigManager.getDistance();
        expect(savedRange, equals(validRange));
      });

      test('無効な距離範囲でArgumentErrorを投げる', () async {
        // Arrange
        const invalidRange = 99;

        // Act & Assert
        expect(
          () => DistanceConfigManager.saveDistance(invalidRange),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('すべての有効な距離範囲を保存できる', () async {
        // Arrange
        const validRanges = [1, 2, 3, 4, 5]; // 300m, 500m, 1000m, 2000m, 3000m

        // Act & Assert
        for (final range in validRanges) {
          await DistanceConfigManager.saveDistance(range);
          final savedRange = await DistanceConfigManager.getDistance();
          expect(savedRange, equals(range));
        }
      });
    });

    group('getDistance', () {
      test('初期値はデフォルトの距離範囲を返す', () async {
        // Act
        final distance = await DistanceConfigManager.getDistance();

        // Assert
        expect(distance, equals(SearchConfig.defaultRange));
        expect(distance, equals(3)); // 1000m
      });

      test('保存した距離設定を取得できる', () async {
        // Arrange
        const savedRange = 5; // 3000m
        await DistanceConfigManager.saveDistance(savedRange);

        // Act
        final retrievedRange = await DistanceConfigManager.getDistance();

        // Assert
        expect(retrievedRange, equals(savedRange));
      });
    });

    group('getDistanceInMeters', () {
      test('距離範囲をメートルに変換して取得できる', () async {
        // Arrange
        const range = 4; // 2000m
        await DistanceConfigManager.saveDistance(range);

        // Act
        final meters = await DistanceConfigManager.getDistanceInMeters();

        // Assert
        expect(meters, equals(2000));
      });

      test('デフォルト値をメートルで取得できる', () async {
        // Act
        final meters = await DistanceConfigManager.getDistanceInMeters();

        // Assert
        expect(meters, equals(1000)); // defaultRange=3の場合
      });

      test('すべての距離範囲が正しくメートルに変換される', () async {
        // Arrange & Act & Assert
        final expectedMap = {
          1: 300,
          2: 500,
          3: 1000,
          4: 2000,
          5: 3000,
        };

        for (final entry in expectedMap.entries) {
          await DistanceConfigManager.saveDistance(entry.key);
          final meters = await DistanceConfigManager.getDistanceInMeters();
          expect(meters, equals(entry.value));
        }
      });
    });
  });
}
