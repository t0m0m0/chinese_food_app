import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/utils/map_utils.dart';

void main() {
  group('MapUtils', () {
    group('isValidCoordinate', () {
      test('should return true for valid latitude and longitude', () {
        // Valid coordinates (Tokyo)
        expect(MapUtils.isValidCoordinate(35.6762, 139.6503), isTrue);

        // Edge cases - valid boundaries
        expect(MapUtils.isValidCoordinate(90.0, 180.0), isTrue);
        expect(MapUtils.isValidCoordinate(-90.0, -180.0), isTrue);
        expect(MapUtils.isValidCoordinate(0.0, 0.0), isTrue);
      });

      test('should return false for invalid latitude', () {
        // Latitude out of range
        expect(MapUtils.isValidCoordinate(90.1, 139.6503), isFalse);
        expect(MapUtils.isValidCoordinate(-90.1, 139.6503), isFalse);
        expect(MapUtils.isValidCoordinate(200.0, 139.6503), isFalse);
      });

      test('should return false for invalid longitude', () {
        // Longitude out of range
        expect(MapUtils.isValidCoordinate(35.6762, 180.1), isFalse);
        expect(MapUtils.isValidCoordinate(35.6762, -180.1), isFalse);
        expect(MapUtils.isValidCoordinate(35.6762, 360.0), isFalse);
      });

      test('should return false for NaN or infinity values', () {
        expect(MapUtils.isValidCoordinate(double.nan, 139.6503), isFalse);
        expect(MapUtils.isValidCoordinate(35.6762, double.nan), isFalse);
        expect(MapUtils.isValidCoordinate(double.infinity, 139.6503), isFalse);
        expect(MapUtils.isValidCoordinate(35.6762, double.infinity), isFalse);
        expect(MapUtils.isValidCoordinate(double.negativeInfinity, 139.6503),
            isFalse);
        expect(MapUtils.isValidCoordinate(35.6762, double.negativeInfinity),
            isFalse);
      });
    });

    group('isValidGoogleMapsApiKey', () {
      test('should return true for valid API key', () {
        const validApiKey = 'AIzaSyBvOkBOwOxWWN83WM6-5l8Kpj1zKsL4g7E';
        expect(MapUtils.isValidGoogleMapsApiKey(validApiKey), isTrue);
      });

      test('should return false for null or empty API key', () {
        expect(MapUtils.isValidGoogleMapsApiKey(null), isFalse);
        expect(MapUtils.isValidGoogleMapsApiKey(''), isFalse);
        expect(MapUtils.isValidGoogleMapsApiKey('   '), isFalse);
      });

      test('should return false for dummy or placeholder keys', () {
        expect(
            MapUtils.isValidGoogleMapsApiKey(
                'AIzaSyDUMMY_KEY_FOR_CI_ENVIRONMENT'),
            isFalse);
        expect(MapUtils.isValidGoogleMapsApiKey('YOUR_API_KEY_HERE'), isFalse);
      });

      test('should return false for invalid format API key', () {
        expect(MapUtils.isValidGoogleMapsApiKey('invalid-key'), isFalse);
        expect(MapUtils.isValidGoogleMapsApiKey('123456'), isFalse);
        expect(MapUtils.isValidGoogleMapsApiKey('random-string'), isFalse);
      });

      test('should return true for valid format but potentially inactive key',
          () {
        // Valid format but may not be active (still should pass format validation)
        const validFormatKey = 'AIzaSyBvOkBOwOxWWN83WM6-5l8Kpj1zKsL4g7A';
        expect(MapUtils.isValidGoogleMapsApiKey(validFormatKey), isTrue);
      });
    });
  });
}
