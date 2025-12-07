import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:chinese_food_app/core/network/api_response.dart';
import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';

void main() {
  group('AppHttpClient', () {
    late AppHttpClient httpClient;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      httpClient = AppHttpClient(client: mockHttpClient);
    });

    group('Configuration', () {
      test('should have default timeout configuration', () {
        // Act
        final client = AppHttpClient();

        // Assert
        expect(client.timeout, equals(const Duration(seconds: 30)));
      });

      test('should allow custom timeout configuration', () {
        // Arrange
        const customTimeout = Duration(seconds: 60);

        // Act
        final client = AppHttpClient(timeout: customTimeout);

        // Assert
        expect(client.timeout, equals(customTimeout));
      });

      test('should have default retry configuration', () {
        // Act
        final client = AppHttpClient();

        // Assert
        expect(client.maxRetries, equals(3));
      });

      test('should allow custom retry configuration', () {
        // Act
        final client = AppHttpClient(maxRetries: 5);

        // Assert
        expect(client.maxRetries, equals(5));
      });
    });

    group('GET requests', () {
      test('should make GET request with proper headers', () async {
        // Arrange
        const url = 'https://api.example.com/test';
        mockHttpClient.stubGet(url, statusCode: 200, body: '{"success": true}');

        // Act
        final response = await httpClient.get(url);

        // Assert
        expect(response.isSuccess, isTrue);
        expect(response.data, equals('{"success": true}'));
        expect(mockHttpClient.lastRequest?.headers,
            containsPair('Content-Type', 'application/json'));
        expect(mockHttpClient.lastRequest?.headers,
            containsPair('Accept', 'application/json'));
      });

      test('should add custom headers to GET request', () async {
        // Arrange
        const url = 'https://api.example.com/test';
        const customHeaders = {'Authorization': 'Bearer token123'};
        mockHttpClient.stubGet(url, statusCode: 200, body: '{}');

        // Act
        await httpClient.get(url, headers: customHeaders);

        // Assert
        expect(mockHttpClient.lastRequest?.headers,
            containsPair('Authorization', 'Bearer token123'));
        expect(mockHttpClient.lastRequest?.headers,
            containsPair('Content-Type', 'application/json'));
      });

      test('should handle network timeout', () async {
        // Arrange
        const url = 'https://api.example.com/timeout';
        mockHttpClient.stubTimeout(url);

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>().having(
            (e) => e.message,
            'message',
            contains('timeout'),
          )),
        );
      });

      test('should handle HTTP error status codes', () async {
        // Arrange
        const url = 'https://api.example.com/error';
        mockHttpClient.stubGet(url, statusCode: 404, body: 'Not found');

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(404),
          )),
        );
      });
    });

    group('POST requests', () {
      test('should make POST request with body', () async {
        // Arrange
        const url = 'https://api.example.com/create';
        const requestBody = '{"name": "test"}';
        mockHttpClient.stubPost(url, statusCode: 201, body: '{"id": 123}');

        // Act
        final response = await httpClient.post(url, body: requestBody);

        // Assert
        expect(response.isSuccess, isTrue);
        expect(response.statusCode, equals(201));
        expect(mockHttpClient.lastRequest?.body, equals(requestBody));
      });

      test('should make POST request with Map body', () async {
        // Arrange
        const url = 'https://api.example.com/create';
        const requestData = {'name': 'test', 'value': 123};
        mockHttpClient.stubPost(url,
            statusCode: 200, body: '{"success": true}');

        // Act
        final response = await httpClient.post(url, body: requestData);

        // Assert
        expect(response.isSuccess, isTrue);
        expect(mockHttpClient.lastRequest?.body, contains('"name":"test"'));
        expect(mockHttpClient.lastRequest?.body, contains('"value":123'));
      });
    });

    group('Retry mechanism', () {
      test('should retry on network failure', () async {
        // Arrange
        const url = 'https://api.example.com/retry';
        mockHttpClient.stubRetryScenario(url,
            failCount: 2, finalStatusCode: 200, finalBody: '{"success": true}');

        // Act
        final response = await httpClient.get(url);

        // Assert
        expect(response.isSuccess, isTrue);
        expect(mockHttpClient.getRequestCountForUrl(url),
            equals(3)); // 2 failures + 1 success
      });

      test('should fail after max retries exceeded', () async {
        // Arrange
        const url = 'https://api.example.com/fail';
        mockHttpClient.stubRetryScenario(url,
            failCount: 5, finalStatusCode: 500, finalBody: 'Error');

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>()),
        );
        expect(mockHttpClient.getRequestCountForUrl(url),
            equals(4)); // maxRetries + 1
      });

      test('should not retry on 4xx client errors', () async {
        // Arrange
        const url = 'https://api.example.com/client-error';
        mockHttpClient.stubGet(url, statusCode: 400, body: 'Bad request');

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>()),
        );
        expect(mockHttpClient.requestCount,
            equals(1)); // No retry for client errors
      });
    });

    group('Response handling', () {
      test('should return ApiResponse on success', () async {
        // Arrange
        const url = 'https://api.example.com/success';
        const responseBody = '{"message": "success", "data": [1, 2, 3]}';
        mockHttpClient.stubGet(url, statusCode: 200, body: responseBody);

        // Act
        final response = await httpClient.get(url);

        // Assert
        expect(response, isA<ApiResponse>());
        expect(response.isSuccess, isTrue);
        expect(response.statusCode, equals(200));
        expect(response.data, equals(responseBody));
        expect(response.headers, isNotNull);
      });

      test('should handle empty response body', () async {
        // Arrange
        const url = 'https://api.example.com/empty';
        mockHttpClient.stubGet(url, statusCode: 204, body: '');

        // Act
        final response = await httpClient.get(url);

        // Assert
        expect(response.isSuccess, isTrue);
        expect(response.statusCode, equals(204));
        expect(response.data, equals(''));
      });
    });

    group('Error handling', () {
      test('should throw UnifiedNetworkException on network error', () async {
        // Arrange
        const url = 'https://api.example.com/network-error';
        mockHttpClient.stubNetworkError(url);

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>()),
        );
      });

      test('should include original exception in UnifiedNetworkException',
          () async {
        // Arrange
        const url = 'https://api.example.com/error';
        const originalError = 'Connection refused';
        mockHttpClient.stubNetworkError(url, error: originalError);

        // Act & Assert
        await expectLater(
          () => httpClient.get(url),
          throwsA(isA<UnifiedNetworkException>().having(
            (e) => e.message,
            'message',
            contains(originalError),
          )),
        );
      });
    });
  });
}

// Mock HTTP Client for testing
class MockHttpClient extends http.BaseClient {
  http.Request? lastRequest;
  int requestCount = 0;
  final Map<String, MockResponse> _stubs = {};
  final Map<String, MockRetryScenario> _retryStubs = {};
  final Map<String, int> _requestCounts = {};

  void stubGet(String url,
      {required int statusCode,
      required String body,
      Map<String, String>? headers}) {
    _stubs[url] = MockResponse(
        statusCode: statusCode, body: body, headers: headers ?? {});
  }

  void stubPost(String url,
      {required int statusCode,
      required String body,
      Map<String, String>? headers}) {
    _stubs[url] = MockResponse(
        statusCode: statusCode, body: body, headers: headers ?? {});
  }

  void stubTimeout(String url) {
    _stubs[url] = MockResponse(shouldTimeout: true);
  }

  void stubNetworkError(String url, {String error = 'Network error'}) {
    _stubs[url] = MockResponse(shouldThrow: true, error: error);
  }

  void stubRetryScenario(String url,
      {required int failCount,
      required int finalStatusCode,
      required String finalBody}) {
    _retryStubs[url] = MockRetryScenario(
      failCount: failCount,
      finalStatusCode: finalStatusCode,
      finalBody: finalBody,
    );
  }

  int getRequestCountForUrl(String url) {
    return _requestCounts[url] ?? 0;
  }

  void reset() {
    requestCount = 0;
    _stubs.clear();
    _retryStubs.clear();
    _requestCounts.clear();
    lastRequest = null;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;

    // Store the request for verification
    if (request is http.Request) {
      lastRequest = request;
    }

    final urlString = request.url.toString();

    // Handle retry scenarios
    if (_retryStubs.containsKey(urlString)) {
      final scenario = _retryStubs[urlString]!;
      // Get the request count for this specific URL
      int requestCountForUrl = _requestCounts[urlString] ?? 0;
      requestCountForUrl++;
      _requestCounts[urlString] = requestCountForUrl;

      if (requestCountForUrl <= scenario.failCount) {
        throw Exception('Simulated network failure');
      } else {
        final response =
            http.Response(scenario.finalBody, scenario.finalStatusCode);
        return http.StreamedResponse(
          Stream.value(response.bodyBytes),
          scenario.finalStatusCode,
          headers: response.headers,
        );
      }
    }

    // Handle regular stubs
    if (_stubs.containsKey(urlString)) {
      final stub = _stubs[urlString]!;

      if (stub.shouldTimeout) {
        throw TimeoutException('Request timeout', const Duration(seconds: 30));
      }

      if (stub.shouldThrow) {
        throw Exception(stub.error);
      }

      final response =
          http.Response(stub.body, stub.statusCode, headers: stub.headers);
      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        stub.statusCode,
        headers: stub.headers,
      );
    }

    // Default response
    final response = http.Response('{}', 200);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      200,
      headers: {},
    );
  }
}

class MockResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final bool shouldTimeout;
  final bool shouldThrow;
  final String error;

  MockResponse({
    this.statusCode = 200,
    this.body = '',
    this.headers = const {},
    this.shouldTimeout = false,
    this.shouldThrow = false,
    this.error = 'Error',
  });
}

class MockRetryScenario {
  final int failCount;
  final int finalStatusCode;
  final String finalBody;

  MockRetryScenario({
    required this.failCount,
    required this.finalStatusCode,
    required this.finalBody,
  });
}
