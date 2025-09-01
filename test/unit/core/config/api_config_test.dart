import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/api_config.dart';

void main() {
  group('ApiConfig Tests', () {
    test('should have correct default values', () {
      expect(ApiConfig.hotpepperApiUrl,
          'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
      expect(ApiConfig.hotpepperApiTimeout, 10);
      expect(ApiConfig.hotpepperApiRetryCount, 3);
      expect(ApiConfig.hotpepperMaxResults, 100);
      expect(ApiConfig.hotpepperRateLimit, 5);
      expect(ApiConfig.hotpepperDailyLimit, 3000);
      expect(ApiConfig.userAgent, 'MachiApp/1.0.0');
    });

    test('should validate timeout values correctly', () {
      expect(ApiConfig.isValidTimeout(1), true);
      expect(ApiConfig.isValidTimeout(30), true);
      expect(ApiConfig.isValidTimeout(60), true);
      expect(ApiConfig.isValidTimeout(0), false);
      expect(ApiConfig.isValidTimeout(-1), false);
      expect(ApiConfig.isValidTimeout(61), false);
    });

    test('should validate retry count values correctly', () {
      expect(ApiConfig.isValidRetryCount(0), true);
      expect(ApiConfig.isValidRetryCount(3), true);
      expect(ApiConfig.isValidRetryCount(5), true);
      expect(ApiConfig.isValidRetryCount(-1), false);
      expect(ApiConfig.isValidRetryCount(6), false);
    });

    test('should validate max results values correctly', () {
      expect(ApiConfig.isValidMaxResults(1), true);
      expect(ApiConfig.isValidMaxResults(50), true);
      expect(ApiConfig.isValidMaxResults(100), true);
      expect(ApiConfig.isValidMaxResults(0), false);
      expect(ApiConfig.isValidMaxResults(-1), false);
      expect(ApiConfig.isValidMaxResults(101), false);
    });

    test('should provide comprehensive debug info', () {
      final debugInfo = ApiConfig.debugInfo;

      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo['hotpepperApiUrl'], isNotEmpty);
      expect(debugInfo['hotpepperApiTimeout'], isA<int>());
      expect(debugInfo['hotpepperApiRetryCount'], isA<int>());
      expect(debugInfo['hotpepperMaxResults'], isA<int>());
      expect(debugInfo['hotpepperRateLimit'], isA<int>());
      expect(debugInfo['hotpepperDailyLimit'], isA<int>());
      expect(debugInfo['googleMapsApiUrl'], isNotEmpty);
      expect(debugInfo['googleMapsApiTimeout'], isA<int>());
      expect(debugInfo['googleMapsApiRetryCount'], isA<int>());
      expect(debugInfo['userAgent'], isNotEmpty);
    });

    test('should have correct common headers', () {
      final headers = ApiConfig.commonHeaders;

      expect(headers['User-Agent'], 'MachiApp/1.0.0');
      expect(headers['Accept'], 'application/json');
      expect(headers['Content-Type'], 'application/json');
    });

    test('should validate boundary values correctly', () {
      // Timeout boundary tests
      expect(ApiConfig.isValidTimeout(1), true); // min
      expect(ApiConfig.isValidTimeout(60), true); // max
      expect(ApiConfig.isValidTimeout(0), false); // below min
      expect(ApiConfig.isValidTimeout(61), false); // above max

      // Retry count boundary tests
      expect(ApiConfig.isValidRetryCount(0), true); // min
      expect(ApiConfig.isValidRetryCount(5), true); // max
      expect(ApiConfig.isValidRetryCount(-1), false); // below min
      expect(ApiConfig.isValidRetryCount(6), false); // above max

      // Max results boundary tests
      expect(ApiConfig.isValidMaxResults(1), true); // min
      expect(ApiConfig.isValidMaxResults(100), true); // max
      expect(ApiConfig.isValidMaxResults(0), false); // below min
      expect(ApiConfig.isValidMaxResults(101), false); // above max
    });
  });
}
