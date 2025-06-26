import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart';
import 'package:chinese_food_app/data/models/hotpepper_store_model.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

import 'hotpepper_api_datasource_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late HotpepperApiDatasourceImpl datasource;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    datasource = HotpepperApiDatasourceImpl(client: mockClient);
    
    // APIキーをテスト用に設定
    AppConfig.setTestApiKey('test_api_key');
  });

  tearDown(() {
    AppConfig.clearTestApiKey();
  });

  group('HotpepperApiDatasource Tests', () {
    test('should return stores when search is successful', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [
            {
              'id': 'test_shop_001',
              'name': 'テスト中華料理店',
              'address': '東京都渋谷区テスト1-1-1',
              'lat': 35.6762,
              'lng': 139.6503,
              'genre': {'name': '中華料理'},
              'budget': {'name': '～1000円'},
              'access': 'JR渋谷駅徒歩5分',
              'catch': '本格中華をお手軽に！',
              'photo': {'pc': {'l': 'https://example.com/photo.jpg'}},
            }
          ],
          'results_available': 1,
          'results_returned': 1,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
                headers: {'content-type': 'application/json'},
              ));

      // Act
      final result = await datasource.searchStores(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 20,
        start: 1,
      );

      // Assert
      expect(result.shops, hasLength(1));
      expect(result.shops.first.id, 'test_shop_001');
      expect(result.shops.first.name, 'テスト中華料理店');
      expect(result.resultsAvailable, 1);
      expect(result.resultsReturned, 1);
      expect(result.resultsStart, 1);

      // Verify correct API call was made
      verify(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('should handle empty search results', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [],
          'results_available': 0,
          'results_returned': 0,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
              ));

      // Act
      final result = await datasource.searchStores(
        address: '存在しない住所',
        keyword: '中華',
      );

      // Assert
      expect(result.shops, isEmpty);
      expect(result.resultsAvailable, 0);
      expect(result.resultsReturned, 0);
    });

    test('should throw exception when API key is invalid (401)', () async {
      // Arrange
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      // Act & Assert
      expect(
        () => datasource.searchStores(lat: 35.6762, lng: 139.6503),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid API key'),
        )),
      );
    });

    test('should throw exception when rate limit exceeded (429)', () async {
      // Arrange
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Too Many Requests', 429));

      // Act & Assert
      expect(
        () => datasource.searchStores(lat: 35.6762, lng: 139.6503),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API rate limit exceeded'),
        )),
      );
    });

    test('should throw exception on network error', () async {
      // Arrange
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenThrow(Exception('Network connection failed'));

      // Act & Assert
      expect(
        () => datasource.searchStores(lat: 35.6762, lng: 139.6503),
        throwsA(isA<Exception>()),
      );
    });

    test('should use default keyword when not provided', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [],
          'results_available': 0,
          'results_returned': 0,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
              ));

      // Act
      await datasource.searchStores(lat: 35.6762, lng: 139.6503);

      // Assert - API call was made
      verify(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('should build correct query parameters for location search', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [],
          'results_available': 0,
          'results_returned': 0,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
              ));

      // Act
      await datasource.searchStores(
        lat: 35.6762,
        lng: 139.6503,
        keyword: 'ラーメン',
        range: 5,
        count: 50,
        start: 21,
      );

      // Assert - API call was made with correct parameters
      verify(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('should build correct query parameters for address search', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [],
          'results_available': 0,
          'results_returned': 0,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
              ));

      // Act
      await datasource.searchStores(
        address: '東京都渋谷区',
        keyword: '餃子',
      );

      // Assert - API call was made
      verify(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('should throw exception when API key is not configured', () async {
      // Arrange - APIキーをクリア
      AppConfig.clearTestApiKey();

      // Act & Assert
      expect(
        () => datasource.searchStores(lat: 35.6762, lng: 139.6503),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('HotPepper API key is not configured'),
        )),
      );
    });

    test('should include correct headers in API request', () async {
      // Arrange
      final mockJsonResponse = {
        'results': {
          'shop': [],
          'results_available': 0,
          'results_returned': 0,
          'results_start': 1,
        }
      };

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode(mockJsonResponse),
                200,
              ));

      // Act
      await datasource.searchStores(lat: 35.6762, lng: 139.6503);

      // Assert
      verify(mockClient.get(
        any,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MachiApp/1.0.0',
        },
      )).called(1);
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
}