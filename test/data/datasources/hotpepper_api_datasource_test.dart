import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:chinese_food_app/core/network/api_response.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';
import 'package:chinese_food_app/core/constants/app_constants.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('HotpepperApiDatasourceImpl', () {
    late HotpepperApiDatasourceImpl datasource;
    late MockAppHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockAppHttpClient();
      datasource = HotpepperApiDatasourceImpl(mockHttpClient);
      // APIキーをテスト用に設定
      AppConfig.setTestApiKey('test_api_key');
    });

    tearDown(() {
      AppConfig.clearTestApiKey();
    });

    group('Parameter Validation', () {
      test('should throw ValidationException for invalid latitude', () async {
        // Act & Assert
        await expectLater(
          () => datasource.searchStores(lat: -95.0, lng: 139.0),
          throwsA(isA<ValidationException>().having(
            (e) => e.fieldName,
            'fieldName',
            equals('lat'),
          )),
        );

        await expectLater(
          () => datasource.searchStores(lat: 95.0, lng: 139.0),
          throwsA(isA<ValidationException>().having(
            (e) => e.fieldName,
            'fieldName',
            equals('lat'),
          )),
        );
      });

      test('should accept valid parameters', () async {
        // Arrange
        const mockResponse = '''
        {
          "results": {
            "shop": [],
            "results_available": 0,
            "results_returned": 0,
            "results_start": 1
          }
        }
        ''';

        mockHttpClient.stubGet(
          AppConstants.hotpepperApiUrl,
          response: ApiResponse.success(data: mockResponse),
        );

        // Act & Assert
        await expectLater(
          () => datasource.searchStores(
            lat: 35.6917,
            lng: 139.7006,
            range: 3,
            count: 20,
            start: 1,
          ),
          returnsNormally,
        );
      });
    });

    group('Response Parsing', () {
      test('should parse successful response with shops', () async {
        // Arrange
        const mockResponse = '''
        {
          "results": {
            "shop": [
              {
                "id": "J001234567",
                "name": "町中華 龍華楼",
                "address": "東京都新宿区西新宿1-1-1",
                "lat": 35.6917,
                "lng": 139.7006,
                "genre": {"name": "中華料理"},
                "budget": {"name": "～1000円"},
                "access": "JR新宿駅徒歩5分",
                "urls": {"pc": "http://example.com/pc"},
                "photo": {"pc": {"l": "http://example.com/photo.jpg"}},
                "open": "11:00～22:00",
                "close": "年中無休",
                "catch": "昔ながらの町中華！"
              }
            ],
            "results_available": 1,
            "results_returned": 1,
            "results_start": 1
          }
        }
        ''';

        mockHttpClient.stubGet(
          AppConstants.hotpepperApiUrl,
          response: ApiResponse.success(data: mockResponse),
        );

        // Act
        final result = await datasource.searchStores();

        // Assert
        expect(result.shops.length, equals(1));
        expect(result.resultsAvailable, equals(1));
        expect(result.resultsReturned, equals(1));
        expect(result.resultsStart, equals(1));

        final shop = result.shops.first;
        expect(shop.id, equals('J001234567'));
        expect(shop.name, equals('町中華 龍華楼'));
        expect(shop.address, equals('東京都新宿区西新宿1-1-1'));
        expect(shop.lat, equals(35.6917));
        expect(shop.lng, equals(139.7006));
      });

      test('should parse empty response', () async {
        // Arrange
        const mockResponse = '''
        {
          "results": {
            "shop": [],
            "results_available": 0,
            "results_returned": 0,
            "results_start": 1
          }
        }
        ''';

        mockHttpClient.stubGet(
          AppConstants.hotpepperApiUrl,
          response: ApiResponse.success(data: mockResponse),
        );

        // Act
        final result = await datasource.searchStores();

        // Assert
        expect(result.shops, isEmpty);
        expect(result.resultsAvailable, equals(0));
        expect(result.resultsReturned, equals(0));
        expect(result.resultsStart, equals(1));
      });
    });

    group('Error Handling', () {
      test('should handle 401 Unauthorized error', () async {
        // Arrange
        mockHttpClient.stubGetError(
          AppConstants.hotpepperApiUrl,
          NetworkException('Unauthorized', statusCode: 401),
        );

        // Act & Assert
        await expectLater(
          () => datasource.searchStores(),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Invalid API key'),
          )),
        );
      });

      test('should handle 429 Rate Limit error', () async {
        // Arrange
        mockHttpClient.stubGetError(
          AppConstants.hotpepperApiUrl,
          NetworkException('Rate Limited', statusCode: 429),
        );

        // Act & Assert
        await expectLater(
          () => datasource.searchStores(),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('API rate limit exceeded'),
          )),
        );
      });

      test('should handle API parsing error', () async {
        // Arrange
        mockHttpClient.stubGet(
          AppConstants.hotpepperApiUrl,
          response: ApiResponse.success(data: 'invalid json'),
        );

        // Act & Assert
        await expectLater(
          () => datasource.searchStores(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('MockHotpepperApiDatasource Tests', () {
      late MockHotpepperApiDatasource mockDatasource;

      setUp(() {
        mockDatasource = MockHotpepperApiDatasource();
      });

      test('should return mock stores with correct data', () async {
        // Act
        final result = await mockDatasource.searchStores(
          lat: 35.6762,
          lng: 139.6503,
        );

        // Assert
        expect(result.shops, hasLength(2));
        expect(result.shops.first.name, '町中華 龍華楼');
        expect(result.shops.first.genre, '中華料理');
        expect(result.shops.last.name, '中華料理 福来');
        expect(result.resultsAvailable, 2);
        expect(result.resultsReturned, 2);
      });

      test('should simulate network delay', () async {
        // Act
        final stopwatch = Stopwatch()..start();
        await mockDatasource.searchStores();
        stopwatch.stop();

        // Assert - should take at least 500ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(450));
      });
    });
  });
}

// Mock HTTP Client for testing
class MockAppHttpClient extends AppHttpClient {
  GetRequest? lastGetRequest;
  final Map<String, ApiResponse> _getStubs = {};
  final Map<String, Exception> _errorStubs = {};

  MockAppHttpClient() : super();

  void stubGet(String path, {required ApiResponse response}) {
    _getStubs[path] = response;
  }

  void stubGetError(String path, Exception error) {
    _errorStubs[path] = error;
  }

  @override
  Future<ApiResponse> get(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final path = url.toString();
    lastGetRequest = GetRequest(path, headers, queryParameters);

    if (_errorStubs.containsKey(path)) {
      throw _errorStubs[path]!;
    }

    return _getStubs[path] ??
        ApiResponse.success(
            data:
                '{"results": {"shop": [], "results_available": 0, "results_returned": 0, "results_start": 1}}');
  }
}

// Request capture class
class GetRequest {
  final String path;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;

  GetRequest(this.path, this.headers, this.queryParameters);
}
