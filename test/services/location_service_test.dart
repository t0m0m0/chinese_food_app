import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/services/location_service.dart';

// Note: geolocatorは現在無効化されているため、今回はgeocodingのみテスト
void main() {
  late LocationService locationService;

  setUp(() {
    locationService = LocationService();
  });

  group('LocationService Tests', () {
    test('should return current position (dummy data)', () async {
      // Act
      final result = await locationService.getCurrentPosition();

      // Assert
      expect(result.isSuccess, true);
      expect(result.lat, 35.6762); // 東京駅の座標
      expect(result.lng, 139.6503);
      expect(result.error, isNull);
    });

    group('Address to Coordinates (geocoding)', () {
      test('should handle geocoding operations', () async {
        // Act - テスト環境では実際のAPIコールの成功/失敗は環境依存
        final result =
            await locationService.getCoordinatesFromAddress('東京都千代田区');

        // Assert - 結果の形式が正しいことを確認
        expect(result.isSuccess, isA<bool>());
        if (result.isSuccess) {
          expect(result.lat, isNotNull);
          expect(result.lng, isNotNull);
          expect(result.address, isNotNull);
          expect(result.error, isNull);
        } else {
          expect(result.error, isNotNull);
          expect(result.lat, isNull);
          expect(result.lng, isNull);
        }
      });

      test('should handle empty address string', () async {
        // Act
        final result = await locationService.getCoordinatesFromAddress('');

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });

      test('should handle invalid address', () async {
        // Act - 明らかに存在しない住所
        final result = await locationService
            .getCoordinatesFromAddress('InvalidAddress123XYZ456');

        // Assert - 失敗するはず
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });
    });

    group('Coordinates to Address (reverse geocoding)', () {
      test('should handle reverse geocoding operations', () async {
        // Act - 東京駅の座標（テスト環境では結果は環境依存）
        final result =
            await locationService.getAddressFromCoordinates(35.6762, 139.6503);

        // Assert - 結果の形式が正しいことを確認
        expect(result.isSuccess, isA<bool>());
        if (result.isSuccess) {
          expect(result.address, isNotNull);
          expect(result.address!.isNotEmpty, true);
          expect(result.error, isNull);
        } else {
          expect(result.error, isNotNull);
          expect(result.address, isNull);
        }
      });

      test('should handle extreme coordinates', () async {
        // Act - 極端な座標値
        final result =
            await locationService.getAddressFromCoordinates(999.0, 999.0);

        // Assert - 失敗するはず
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });
    });
  });

  group('LocationServiceResult Tests', () {
    test('should create success result correctly', () {
      // Act
      final result = LocationServiceResult.success(lat: 35.6762, lng: 139.6503);

      // Assert
      expect(result.isSuccess, true);
      expect(result.lat, 35.6762);
      expect(result.lng, 139.6503);
      expect(result.error, isNull);
    });

    test('should create failure result correctly', () {
      // Act
      const errorMessage = 'Location error';
      final result = LocationServiceResult.failure(errorMessage);

      // Assert
      expect(result.isSuccess, false);
      expect(result.lat, isNull);
      expect(result.lng, isNull);
      expect(result.error, errorMessage);
    });

    test('should have correct toString representation', () {
      // Act
      final successResult =
          LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
      final failureResult = LocationServiceResult.failure('Error message');

      // Assert
      expect(successResult.toString(), contains('success'));
      expect(successResult.toString(), contains('35.6762'));
      expect(successResult.toString(), contains('139.6503'));

      expect(failureResult.toString(), contains('failure'));
      expect(failureResult.toString(), contains('Error message'));
    });
  });

  group('GeocodeResult Tests', () {
    test('should create success result correctly', () {
      // Act
      final result = GeocodeResult.success(
        '東京都千代田区',
        lat: 35.6762,
        lng: 139.6503,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.address, '東京都千代田区');
      expect(result.lat, 35.6762);
      expect(result.lng, 139.6503);
      expect(result.error, isNull);
    });

    test('should create success result without coordinates', () {
      // Act
      final result = GeocodeResult.success('東京都千代田区');

      // Assert
      expect(result.isSuccess, true);
      expect(result.address, '東京都千代田区');
      expect(result.lat, isNull);
      expect(result.lng, isNull);
      expect(result.error, isNull);
    });

    test('should create failure result correctly', () {
      // Act
      const errorMessage = 'Geocoding error';
      final result = GeocodeResult.failure(errorMessage);

      // Assert
      expect(result.isSuccess, false);
      expect(result.address, isNull);
      expect(result.lat, isNull);
      expect(result.lng, isNull);
      expect(result.error, errorMessage);
    });

    test('should have correct toString representation', () {
      // Act
      final successResult = GeocodeResult.success('東京都千代田区');
      final failureResult = GeocodeResult.failure('Error message');

      // Assert
      expect(successResult.toString(), contains('success'));
      expect(successResult.toString(), contains('東京都千代田区'));

      expect(failureResult.toString(), contains('failure'));
      expect(failureResult.toString(), contains('Error message'));
    });
  });
}
