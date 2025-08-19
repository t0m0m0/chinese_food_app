import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';
import 'package:chinese_food_app/core/network/api_response.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_proxy_datasource.dart';

import 'hotpepper_proxy_datasource_test.mocks.dart';

@GenerateMocks([AppHttpClient])
void main() {
  group('HotpepperProxyDatasourceImpl', () {
    late HotpepperProxyDatasourceImpl datasource;
    late MockAppHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockAppHttpClient();
      datasource = HotpepperProxyDatasourceImpl(
        mockHttpClient,
        proxyBaseUrl: 'https://test-proxy.example.com',
      );
    });

    group('searchStores', () {
      test('正常なレスポンスでHotpepperSearchResponseを返す', () async {
        // Arrange
        final mockResponse = {
          'results': {
            'shop': [
              {
                'id': 'test_001',
                'name': 'テスト中華料理店',
                'address': 'テスト住所',
                'lat': 35.6917,
                'lng': 139.7006,
                'genre': {'name': '中華料理'},
                'budget': {'name': '～1000円'},
                'access': 'テスト駅徒歩5分',
                'catch': 'テストキャッチコピー',
                'photo': {
                  'pc': {'l': 'https://example.com/photo.jpg'}
                },
              }
            ],
            'results_available': 1,
            'results_returned': 1,
            'results_start': 1,
          }
        };

        when(mockHttpClient.post(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockApiResponse(mockResponse));

        // Act
        final result = await datasource.searchStores(
          lat: 35.6917,
          lng: 139.7006,
          keyword: '中華',
        );

        // Assert
        expect(result.shops, hasLength(1));
        expect(result.shops[0].name, equals('テスト中華料理店'));
        expect(result.resultsAvailable, equals(1));

        verify(mockHttpClient.post(
          'https://test-proxy.example.com/api/hotpepper/search',
          body: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['lat'], 'lat', 35.6917)
                .having((m) => m['lng'], 'lng', 139.7006)
                .having((m) => m['keyword'], 'keyword', '中華'),
            named: 'body',
          ),
          headers: argThat(
            containsPair('Content-Type', 'application/json'),
            named: 'headers',
          ),
        )).called(1);
      });

      group('パラメータ検証', () {
        test('緯度が範囲外の場合にValidationExceptionを投げる', () async {
          // Act & Assert
          expect(
            () => datasource.searchStores(lat: -91.0, lng: 139.7006),
            throwsA(isA<ValidationException>().having(
                (e) => e.message, 'message', contains('緯度は-90.0から90.0'))),
          );
        });

        test('経度が範囲外の場合にValidationExceptionを投げる', () async {
          // Act & Assert
          expect(
            () => datasource.searchStores(lat: 35.6917, lng: 181.0),
            throwsA(isA<ValidationException>().having(
                (e) => e.message, 'message', contains('経度は-180.0から180.0'))),
          );
        });

        test('検索範囲が範囲外の場合にValidationExceptionを投げる', () async {
          // Act & Assert
          expect(
            () => datasource.searchStores(
              lat: 35.6917,
              lng: 139.7006,
              range: 6,
            ),
            throwsA(isA<ValidationException>()
                .having((e) => e.message, 'message', contains('検索範囲は1から5'))),
          );
        });

        test('取得件数が範囲外の場合にValidationExceptionを投げる', () async {
          // Act & Assert
          expect(
            () => datasource.searchStores(
              lat: 35.6917,
              lng: 139.7006,
              count: 101,
            ),
            throwsA(isA<ValidationException>()
                .having((e) => e.message, 'message', contains('取得件数は1から100'))),
          );
        });

        test('住所も緯度経度も指定されていない場合にValidationExceptionを投げる', () async {
          // Act & Assert
          expect(
            () => datasource.searchStores(keyword: '中華'),
            throwsA(isA<ValidationException>()
                .having((e) => e.message, 'message', contains('住所または緯度経度を指定'))),
          );
        });
      });

      group('エラーハンドリング', () {
        test('400エラーの場合に適切なApiExceptionを投げる', () async {
          // Arrange
          when(mockHttpClient.post(any,
                  body: anyNamed('body'), headers: anyNamed('headers')))
              .thenThrow(NetworkException('Bad Request', statusCode: 400));

          // Act & Assert
          expect(
            () => datasource.searchStores(lat: 35.6917, lng: 139.7006),
            throwsA(isA<ApiException>()
                .having((e) => e.message, 'message',
                    contains('Invalid request parameters'))
                .having((e) => e.statusCode, 'statusCode', 400)),
          );
        });

        test('429エラーの場合にレート制限エラーを投げる', () async {
          // Arrange
          when(mockHttpClient.post(any,
                  body: anyNamed('body'), headers: anyNamed('headers')))
              .thenThrow(
                  NetworkException('Too Many Requests', statusCode: 429));

          // Act & Assert
          expect(
            () => datasource.searchStores(lat: 35.6917, lng: 139.7006),
            throwsA(isA<ApiException>()
                .having((e) => e.message, 'message',
                    contains('Rate limit exceeded'))
                .having((e) => e.statusCode, 'statusCode', 429)),
          );
        });

        test('500エラーの場合にサーバーエラーを投げる', () async {
          // Arrange
          when(mockHttpClient.post(any,
                  body: anyNamed('body'), headers: anyNamed('headers')))
              .thenThrow(
                  NetworkException('Internal Server Error', statusCode: 500));

          // Act & Assert
          expect(
            () => datasource.searchStores(lat: 35.6917, lng: 139.7006),
            throwsA(isA<ApiException>()
                .having((e) => e.message, 'message',
                    contains('Proxy server internal error'))
                .having((e) => e.statusCode, 'statusCode', 500)),
          );
        });
      });
    });

    group('MockHotpepperProxyDatasource', () {
      test('モックデータを正常に返す', () async {
        // Arrange
        final mockDatasource = MockHotpepperProxyDatasource();

        // Act
        final result = await mockDatasource.searchStores(
          lat: 35.6917,
          lng: 139.7006,
        );

        // Assert
        expect(result.shops, hasLength(2));
        expect(result.shops[0].name, contains('プロキシ経由'));
        expect(result.shops[1].name, contains('プロキシ経由'));
      });
    });
  });
}

// Helper function to create mock API response
ApiResponse mockApiResponse(Map<String, dynamic> responseData) {
  return ApiResponse(
    data: jsonEncode(responseData),
    statusCode: 200,
    headers: {},
  );
}
