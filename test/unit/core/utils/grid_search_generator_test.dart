import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chinese_food_app/core/utils/grid_search_generator.dart';

void main() {
  group('GridSearchGenerator', () {
    group('generateSearchPoints', () {
      test('should return single center point for radius <= 3km', () {
        const center = LatLng(35.6812, 139.7671); // Tokyo
        const radiusMeters = 3000.0;

        final points = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
        );

        expect(points.length, 1);
        expect(points.first.latitude, center.latitude);
        expect(points.first.longitude, center.longitude);
      });

      test('should generate multiple points for radius > 3km', () {
        const center = LatLng(35.6812, 139.7671); // Tokyo
        const radiusMeters = 10000.0; // 10km

        final points = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
        );

        expect(points.length, greaterThan(1));
        // 中心点が含まれている
        expect(
          points.any((p) =>
              (p.latitude - center.latitude).abs() < 0.001 &&
              (p.longitude - center.longitude).abs() < 0.001),
          isTrue,
        );
      });

      test('should generate points that cover the entire search area', () {
        const center = LatLng(35.6812, 139.7671); // Tokyo
        const radiusMeters = 10000.0; // 10km

        final points = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
        );

        // 各ポイントが中心から指定範囲内にあることを確認
        for (final point in points) {
          final distance = GridSearchGenerator.calculateDistance(center, point);
          // グリッド生成の関係上、角の点は半径を少し超える可能性があるため余裕を持たせる
          expect(distance, lessThanOrEqualTo(radiusMeters * 1.5));
        }
      });

      test('should respect the gridSpacing parameter', () {
        const center = LatLng(35.6812, 139.7671);
        const radiusMeters = 20000.0; // 20km for clearer difference
        const widerSpacing = 8000.0; // 8km spacing (wider than default 5km)

        final defaultPoints = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
        );

        final widerSpacingPoints = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
          gridSpacingMeters: widerSpacing,
        );

        // より大きなグリッド間隔は、より少ないポイントを生成
        expect(widerSpacingPoints.length, lessThan(defaultPoints.length));
      });

      test('should generate points for 50km radius', () {
        const center = LatLng(35.6812, 139.7671);
        const radiusMeters = 50000.0; // 50km

        final points = GridSearchGenerator.generateSearchPoints(
          center: center,
          radiusMeters: radiusMeters,
        );

        // 50km半径には複数のポイントが必要
        expect(points.length, greaterThan(10));
      });
    });

    group('calculateDistance', () {
      test('should return 0 for same point', () {
        const point = LatLng(35.6812, 139.7671);
        final distance = GridSearchGenerator.calculateDistance(point, point);
        expect(distance, 0);
      });

      test('should calculate distance between two points correctly', () {
        const tokyo = LatLng(35.6812, 139.7671);
        const yokohama = LatLng(35.4437, 139.6380);

        final distance = GridSearchGenerator.calculateDistance(tokyo, yokohama);

        // 東京-横浜間は約27km
        expect(distance, closeTo(27000, 2000));
      });
    });

    group('isWideAreaSearch', () {
      test('should return false for radius <= 3km', () {
        expect(GridSearchGenerator.isWideAreaSearch(3000), isFalse);
        expect(GridSearchGenerator.isWideAreaSearch(2000), isFalse);
        expect(GridSearchGenerator.isWideAreaSearch(1000), isFalse);
      });

      test('should return true for radius > 3km', () {
        expect(GridSearchGenerator.isWideAreaSearch(3001), isTrue);
        expect(GridSearchGenerator.isWideAreaSearch(5000), isTrue);
        expect(GridSearchGenerator.isWideAreaSearch(50000), isTrue);
      });
    });

    group('estimateApiCalls', () {
      test('should return 1 for radius <= 3km', () {
        const center = LatLng(35.6812, 139.7671);
        expect(
          GridSearchGenerator.estimateApiCalls(
              center: center, radiusMeters: 3000),
          1,
        );
      });

      test('should return multiple calls for wide area search', () {
        const center = LatLng(35.6812, 139.7671);
        final calls = GridSearchGenerator.estimateApiCalls(
          center: center,
          radiusMeters: 10000,
        );
        expect(calls, greaterThan(1));
      });
    });
  });
}
