import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/network/base_api_service.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:chinese_food_app/core/network/api_response.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';

void main() {
  group('BaseApiService', () {
    late TestApiService apiService;
    late MockAppHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockAppHttpClient();
      apiService = TestApiService(mockHttpClient);
    });

    group('JSON Parsing', () {
      test('should parse valid JSON response successfully', () async {
        // Arrange
        const jsonResponse = '{"name": "test", "value": 123}';
        mockHttpClient.stubGet('/test',
            response: ApiResponse.success(data: jsonResponse));

        // Act
        final result = await apiService.getAndParse(
          '/test',
          (json) => TestModel.fromJson(json as Map<String, dynamic>),
        );

        // Assert
        expect(result.name, equals('test'));
        expect(result.value, equals(123));
      });

      test('should handle empty response gracefully', () async {
        // Arrange
        mockHttpClient.stubGet('/empty',
            response: ApiResponse.success(data: ''));

        // Act
        final result = await apiService.getAndParse(
          '/empty',
          (json) => json == null ? 'empty' : 'not_empty',
        );

        // Assert
        expect(result, equals('empty'));
      });

      test('should throw ApiException on invalid JSON', () async {
        // Arrange
        const invalidJson = '{invalid json}';
        mockHttpClient.stubGet('/invalid',
            response: ApiResponse.success(data: invalidJson));

        // Act & Assert
        await expectLater(
          () => apiService.getAndParse('/invalid', (json) => json),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Invalid JSON response'),
          )),
        );
      });

      test('should throw ApiException on parsing error', () async {
        // Arrange
        const jsonResponse = '{"name": "test"}';
        mockHttpClient.stubGet('/parse-error',
            response: ApiResponse.success(data: jsonResponse));

        // Act & Assert
        await expectLater(
          () => apiService.getAndParse(
            '/parse-error',
            (json) => throw Exception('Parsing failed'),
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Response parsing failed'),
          )),
        );
      });
    });

    group('HTTP Methods', () {
      test('should perform GET request with proper parameters', () async {
        // Arrange
        const path = '/users';
        const headers = {'Authorization': 'Bearer token'};
        const queryParams = {'page': '1', 'limit': '10'};
        mockHttpClient.stubGet(path, response: ApiResponse.success(data: '[]'));

        // Act
        await apiService.getAndParse(
          path,
          (json) => json,
          headers: headers,
          queryParameters: queryParams,
        );

        // Assert
        expect(mockHttpClient.lastGetRequest?.path, equals(path));
        expect(mockHttpClient.lastGetRequest?.headers, equals(headers));
        expect(mockHttpClient.lastGetRequest?.queryParameters,
            equals(queryParams));
      });

      test('should perform POST request with body', () async {
        // Arrange
        const path = '/users';
        const body = {'name': 'John', 'email': 'john@example.com'};
        mockHttpClient.stubPost(path,
            response: ApiResponse.success(data: '{"id": 1}'));

        // Act
        await apiService.postAndParse(
          path,
          (json) => json,
          body: body,
        );

        // Assert
        expect(mockHttpClient.lastPostRequest?.path, equals(path));
        expect(mockHttpClient.lastPostRequest?.body, equals(body));
      });

      test('should perform PUT request with body', () async {
        // Arrange
        const path = '/users/1';
        const body = {'name': 'John Updated'};
        mockHttpClient.stubPut(path,
            response: ApiResponse.success(data: '{"success": true}'));

        // Act
        await apiService.putAndParse(
          path,
          (json) => json,
          body: body,
        );

        // Assert
        expect(mockHttpClient.lastPutRequest?.path, equals(path));
        expect(mockHttpClient.lastPutRequest?.body, equals(body));
      });

      test('should perform DELETE request', () async {
        // Arrange
        const path = '/users/1';
        mockHttpClient.stubDelete(path,
            response: ApiResponse.success(data: '{"success": true}'));

        // Act
        await apiService.deleteAndParse(
          path,
          (json) => json,
        );

        // Assert
        expect(mockHttpClient.lastDeleteRequest?.path, equals(path));
      });
    });

    group('Raw Requests', () {
      test('should return raw response for GET request', () async {
        // Arrange
        const path = '/raw-test';
        const responseData = 'raw response data';
        final expectedResponse = ApiResponse.success(data: responseData);
        mockHttpClient.stubGet(path, response: expectedResponse);

        // Act
        final result = await apiService.getRaw(path);

        // Assert
        expect(result.data, equals(responseData));
        expect(result.isSuccess, isTrue);
      });

      test('should return raw response for POST request', () async {
        // Arrange
        const path = '/raw-post';
        const body = 'raw body data';
        const responseData = 'raw response';
        final expectedResponse = ApiResponse.success(data: responseData);
        mockHttpClient.stubPost(path, response: expectedResponse);

        // Act
        final result = await apiService.postRaw(path, body: body);

        // Assert
        expect(result.data, equals(responseData));
        expect(result.isSuccess, isTrue);
        expect(mockHttpClient.lastPostRequest?.body, equals(body));
      });
    });

    group('Field Validation', () {
      test('should validate required fields successfully', () {
        // Arrange
        final json = {'name': 'test', 'email': 'test@example.com', 'age': 25};
        final requiredFields = ['name', 'email'];

        // Act & Assert
        expect(
          () => apiService.validateRequiredFields(json, requiredFields),
          returnsNormally,
        );
      });

      test('should throw ApiException for missing required fields', () {
        // Arrange
        final json = {'name': 'test'};
        final requiredFields = ['name', 'email', 'age'];

        // Act & Assert
        expect(
          () => apiService.validateRequiredFields(json, requiredFields),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Missing required fields: email, age'),
          )),
        );
      });
    });

    group('Safe Value Extraction', () {
      test('should extract string values safely', () {
        // Arrange
        final json = {
          'string': 'test',
          'number': 123,
          'null': null,
        };

        // Act & Assert
        expect(apiService.getStringValue(json, 'string'), equals('test'));
        expect(apiService.getStringValue(json, 'number'), equals('123'));
        expect(apiService.getStringValue(json, 'null'), equals(''));
        expect(apiService.getStringValue(json, 'missing'), equals(''));
        expect(apiService.getStringValue(json, 'missing', 'default'),
            equals('default'));
      });

      test('should extract integer values safely', () {
        // Arrange
        final json = {
          'int': 123,
          'string': '456',
          'double': 789.5,
          'invalid': 'abc',
          'null': null,
        };

        // Act & Assert
        expect(apiService.getIntValue(json, 'int'), equals(123));
        expect(apiService.getIntValue(json, 'string'), equals(456));
        expect(apiService.getIntValue(json, 'double'), equals(790));
        expect(apiService.getIntValue(json, 'invalid'), equals(0));
        expect(apiService.getIntValue(json, 'null'), equals(0));
        expect(apiService.getIntValue(json, 'missing', 99), equals(99));
      });

      test('should extract double values safely', () {
        // Arrange
        final json = {
          'double': 123.45,
          'int': 789,
          'string': '456.78',
          'invalid': 'abc',
          'null': null,
        };

        // Act & Assert
        expect(apiService.getDoubleValue(json, 'double'), equals(123.45));
        expect(apiService.getDoubleValue(json, 'int'), equals(789.0));
        expect(apiService.getDoubleValue(json, 'string'), equals(456.78));
        expect(apiService.getDoubleValue(json, 'invalid'), equals(0.0));
        expect(apiService.getDoubleValue(json, 'null'), equals(0.0));
        expect(apiService.getDoubleValue(json, 'missing', 99.9), equals(99.9));
      });

      test('should extract boolean values safely', () {
        // Arrange
        final json = {
          'bool_true': true,
          'bool_false': false,
          'string_true': 'true',
          'string_false': 'false',
          'string_1': '1',
          'string_0': '0',
          'int_1': 1,
          'int_0': 0,
          'null': null,
        };

        // Act & Assert
        expect(apiService.getBoolValue(json, 'bool_true'), isTrue);
        expect(apiService.getBoolValue(json, 'bool_false'), isFalse);
        expect(apiService.getBoolValue(json, 'string_true'), isTrue);
        expect(apiService.getBoolValue(json, 'string_false'), isFalse);
        expect(apiService.getBoolValue(json, 'string_1'), isTrue);
        expect(apiService.getBoolValue(json, 'string_0'), isFalse);
        expect(apiService.getBoolValue(json, 'int_1'), isTrue);
        expect(apiService.getBoolValue(json, 'int_0'), isFalse);
        expect(apiService.getBoolValue(json, 'null'), isFalse);
        expect(apiService.getBoolValue(json, 'missing', true), isTrue);
      });

      test('should extract list values safely', () {
        // Arrange
        final json = {
          'list_string': ['a', 'b', 'c'],
          'list_int': [1, 2, 3],
          'list_mixed': [1, 'b', 3],
          'null': null,
        };

        // Act & Assert
        expect(apiService.getListValue<String>(json, 'list_string'),
            equals(['a', 'b', 'c']));
        expect(
            apiService.getListValue<int>(json, 'list_int'), equals([1, 2, 3]));
        expect(
            apiService.getListValue(json, 'list_mixed'), equals([1, 'b', 3]));
        expect(apiService.getListValue(json, 'null'), equals([]));
        expect(apiService.getListValue(json, 'missing', ['default']),
            equals(['default']));
      });
    });

    group('Error Propagation', () {
      test('should propagate NetworkException from HTTP client', () async {
        // Arrange
        mockHttpClient.stubGetError(
            '/error', NetworkException('Network failed'));

        // Act & Assert
        await expectLater(
          () => apiService.getAndParse('/error', (json) => json),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            equals('Network failed'),
          )),
        );
      });

      test('should propagate ApiException from parsing', () async {
        // Arrange
        mockHttpClient.stubGet('/api-error',
            response: ApiResponse.success(data: '{"data": "test"}'));

        // Act & Assert
        await expectLater(
          () => apiService.getAndParse(
            '/api-error',
            (json) => throw ApiException('Custom parsing error'),
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            equals('Custom parsing error'),
          )),
        );
      });
    });
  });
}

// Test implementation of BaseApiService
class TestApiService extends BaseApiService {
  TestApiService(super.httpClient);
}

// Test model for JSON parsing
class TestModel {
  final String name;
  final int value;

  TestModel({required this.name, required this.value});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      name: json['name'] as String,
      value: json['value'] as int,
    );
  }
}

// Mock HTTP Client for testing
class MockAppHttpClient extends AppHttpClient {
  GetRequest? lastGetRequest;
  PostRequest? lastPostRequest;
  PutRequest? lastPutRequest;
  DeleteRequest? lastDeleteRequest;

  final Map<String, ApiResponse> _getStubs = {};
  final Map<String, ApiResponse> _postStubs = {};
  final Map<String, ApiResponse> _putStubs = {};
  final Map<String, ApiResponse> _deleteStubs = {};
  final Map<String, Exception> _errorStubs = {};

  MockAppHttpClient() : super();

  void stubGet(String path, {required ApiResponse response}) {
    _getStubs[path] = response;
  }

  void stubPost(String path, {required ApiResponse response}) {
    _postStubs[path] = response;
  }

  void stubPut(String path, {required ApiResponse response}) {
    _putStubs[path] = response;
  }

  void stubDelete(String path, {required ApiResponse response}) {
    _deleteStubs[path] = response;
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

    return _getStubs[path] ?? ApiResponse.success(data: '{}');
  }

  @override
  Future<ApiResponse> post(
    dynamic url, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final path = url.toString();
    lastPostRequest = PostRequest(path, body, headers, queryParameters);

    if (_errorStubs.containsKey(path)) {
      throw _errorStubs[path]!;
    }

    return _postStubs[path] ?? ApiResponse.success(data: '{}');
  }

  @override
  Future<ApiResponse> put(
    dynamic url, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final path = url.toString();
    lastPutRequest = PutRequest(path, body, headers, queryParameters);

    if (_errorStubs.containsKey(path)) {
      throw _errorStubs[path]!;
    }

    return _putStubs[path] ?? ApiResponse.success(data: '{}');
  }

  @override
  Future<ApiResponse> delete(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final path = url.toString();
    lastDeleteRequest = DeleteRequest(path, headers, queryParameters);

    if (_errorStubs.containsKey(path)) {
      throw _errorStubs[path]!;
    }

    return _deleteStubs[path] ?? ApiResponse.success(data: '{}');
  }
}

// Request capture classes
class GetRequest {
  final String path;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;

  GetRequest(this.path, this.headers, this.queryParameters);
}

class PostRequest {
  final String path;
  final dynamic body;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;

  PostRequest(this.path, this.body, this.headers, this.queryParameters);
}

class PutRequest {
  final String path;
  final dynamic body;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;

  PutRequest(this.path, this.body, this.headers, this.queryParameters);
}

class DeleteRequest {
  final String path;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;

  DeleteRequest(this.path, this.headers, this.queryParameters);
}
