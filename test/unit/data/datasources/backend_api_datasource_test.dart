import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';
import 'package:chinese_food_app/core/network/api_response.dart';
import 'package:chinese_food_app/data/datasources/backend_api_datasource.dart';
import 'package:chinese_food_app/data/models/hotpepper_store_model.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  group('BackendApiDatasourceImpl', () {
    late BackendApiDatasourceImpl datasource;
    late MockAppHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockAppHttpClient();
      datasource = BackendApiDatasourceImpl(
        mockHttpClient,
        baseUrl: 'https://api.test.com',
        apiToken: 'test_token_12345',
      );
    });

    group('searchStores', () {
      test('正常なレスポンスの場合、HotpepperSearchResponseを返す', () async {
        // Arrange
        final responseJson = {
          'success': true,
          'data': {
            'stores': [
              {
                'id': 'store_001',
                'name': '町中華 龍華楼',
                'address': '東京都新宿区西新宿1-1-1',
                'lat': 35.6917,
                'lng': 139.7006,
                'genre': {'name': '中華料理'},
                'budget': {'average': '～1000円'},
                'access': 'JR新宿駅徒歩5分',
                'catch': '昔ながらの町中華！',
                'photo': {
                  'pc': {'l': 'https://example.com/photo.jpg'}
                },
              }
            ],
            'pagination': {'totalCount': 1, 'currentPage': 1, 'totalPages': 1}
          }
        };

        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse.success(
                  statusCode: 200,
                  data: jsonEncode(responseJson),
                  headers: {'content-type': 'application/json'},
                ));

        // Act
        final result = await datasource.searchStores(
          lat: 35.6917,
          lng: 139.7006,
          keyword: '中華',
          range: 3,
          count: 20,
          start: 1,
        );

        // Assert
        expect(result.shops, hasLength(1));
        expect(result.shops.first.name, '町中華 龍華楼');
        expect(result.resultsAvailable, 1);
        expect(result.resultsReturned, 1);
        expect(result.resultsStart, 1);
      });

      test('認証エラーの場合、ApiExceptionをthrowする', () async {
        // Arrange
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => ApiResponse.error(
                  statusCode: 401,
                  errorMessage: 'Unauthorized',
                  data: jsonEncode({'error': 'Unauthorized'}),
                ));

        // Act & Assert
        expect(
          () async =>
              await datasource.searchStores(lat: 35.6917, lng: 139.7006),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Backend API'),
          )),
        );
      });

      test('不正なパラメータでValidationExceptionをthrowする', () async {
        // Act & Assert
        expect(
          () async => await datasource.searchStores(lat: -95.0, lng: 139.7006),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('緯度'),
          )),
        );
      });

      test('APIトークンが未設定の場合、ApiExceptionをthrowする', () async {
        // Arrange
        final invalidDatasource = BackendApiDatasourceImpl(
          mockHttpClient,
          baseUrl: 'https://api.test.com',
          apiToken: '', // 空のトークン
        );

        // Act & Assert
        expect(
          () async =>
              await invalidDatasource.searchStores(lat: 35.6917, lng: 139.7006),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('APIトークン'),
          )),
        );
      });
    });
  });
}
