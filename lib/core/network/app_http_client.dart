import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../exceptions/domain_exceptions.dart';
import 'api_response.dart';

/// Unified HTTP client for the application
///
/// This class provides a consistent interface for all HTTP communications
/// across the application with built-in retry mechanism, timeout handling,
/// and standardized error processing.
///
/// Features:
/// - Automatic retry on network failures
/// - Configurable timeout settings
/// - Standardized request/response headers
/// - Unified error handling
/// - Logging for debugging
///
/// Example usage:
/// ```dart
/// final httpClient = AppHttpClient();
/// final response = await httpClient.get('https://api.example.com/users');
/// if (response.isSuccess) {
///   final users = jsonDecode(response.data);
/// }
/// ```
class AppHttpClient {
  final http.Client _client;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  /// Creates an AppHttpClient instance
  ///
  /// [client] - Optional HTTP client (defaults to http.Client())
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [maxRetries] - Maximum number of retries (default: 3)
  /// [retryDelay] - Delay between retries (default: 1 second)
  AppHttpClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  }) : _client = client ?? http.Client();

  /// Default headers applied to all requests
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'MachiApp/1.0.0',
      };

  /// Performs a GET request
  ///
  /// [url] - Request URL (String or Uri)
  /// [headers] - Additional headers to include
  /// [queryParameters] - URL query parameters
  ///
  /// Returns [ApiResponse] with the response data
  /// Throws [NetworkException] on network errors
  Future<ApiResponse> get(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(url, queryParameters);
    final requestHeaders = _mergeHeaders(headers);

    return _executeWithRetry(() async {
      developer.log('GET $uri', name: 'HTTP');

      try {
        final response =
            await _client.get(uri, headers: requestHeaders).timeout(timeout);

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw NetworkException('Request timeout: ${e.message}');
      }
    });
  }

  /// Performs a POST request
  ///
  /// [url] - Request URL (String or Uri)
  /// [body] - Request body (String, Map, or List)
  /// [headers] - Additional headers to include
  /// [queryParameters] - URL query parameters
  ///
  /// Returns [ApiResponse] with the response data
  /// Throws [NetworkException] on network errors
  Future<ApiResponse> post(
    dynamic url, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(url, queryParameters);
    final requestHeaders = _mergeHeaders(headers);
    final requestBody = _encodeBody(body);

    return _executeWithRetry(() async {
      developer.log('POST $uri', name: 'HTTP');

      try {
        final response = await _client
            .post(uri, headers: requestHeaders, body: requestBody)
            .timeout(timeout);

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw NetworkException('Request timeout: ${e.message}');
      }
    });
  }

  /// Performs a PUT request
  ///
  /// [url] - Request URL (String or Uri)
  /// [body] - Request body (String, Map, or List)
  /// [headers] - Additional headers to include
  /// [queryParameters] - URL query parameters
  ///
  /// Returns [ApiResponse] with the response data
  /// Throws [NetworkException] on network errors
  Future<ApiResponse> put(
    dynamic url, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(url, queryParameters);
    final requestHeaders = _mergeHeaders(headers);
    final requestBody = _encodeBody(body);

    return _executeWithRetry(() async {
      developer.log('PUT $uri', name: 'HTTP');

      try {
        final response = await _client
            .put(uri, headers: requestHeaders, body: requestBody)
            .timeout(timeout);

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw NetworkException('Request timeout: ${e.message}');
      }
    });
  }

  /// Performs a DELETE request
  ///
  /// [url] - Request URL (String or Uri)
  /// [headers] - Additional headers to include
  /// [queryParameters] - URL query parameters
  ///
  /// Returns [ApiResponse] with the response data
  /// Throws [NetworkException] on network errors
  Future<ApiResponse> delete(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(url, queryParameters);
    final requestHeaders = _mergeHeaders(headers);

    return _executeWithRetry(() async {
      developer.log('DELETE $uri', name: 'HTTP');

      try {
        final response =
            await _client.delete(uri, headers: requestHeaders).timeout(timeout);

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw NetworkException('Request timeout: ${e.message}');
      }
    });
  }

  /// Builds URI from URL and query parameters
  Uri _buildUri(dynamic url, Map<String, String>? queryParameters) {
    Uri uri;
    if (url is String) {
      uri = Uri.parse(url);
    } else if (url is Uri) {
      uri = url;
    } else {
      throw ArgumentError('URL must be String or Uri');
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
    }

    return uri;
  }

  /// Merges default headers with custom headers
  Map<String, String> _mergeHeaders(Map<String, String>? customHeaders) {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Encodes request body to string
  String? _encodeBody(dynamic body) {
    if (body == null) return null;

    if (body is String) {
      return body;
    } else if (body is Map || body is List) {
      return jsonEncode(body);
    } else {
      return body.toString();
    }
  }

  /// Executes HTTP request with retry mechanism
  Future<ApiResponse> _executeWithRetry(
    Future<ApiResponse> Function() operation,
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts <= maxRetries) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;
        attempts++;

        // Don't retry on client errors (4xx)
        if (e is NetworkException && e.isClientError) {
          rethrow;
        }

        if (attempts <= maxRetries) {
          developer.log(
            'HTTP request failed (attempt $attempts/${maxRetries + 1}): $e',
            name: 'HTTP',
            level: 900, // WARNING
          );

          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      }
    }

    // All retries exhausted - wrap in NetworkException if needed
    if (lastException != null) {
      if (lastException is NetworkException) {
        throw lastException;
      } else {
        throw NetworkException(
          'Network request failed: ${lastException.toString()}',
        );
      }
    } else {
      throw NetworkException('HTTP request failed after $maxRetries retries');
    }
  }

  /// Handles HTTP response and creates ApiResponse
  ApiResponse _handleResponse(http.Response response) {
    developer.log(
      'HTTP ${response.statusCode} - ${response.body.length} bytes',
      name: 'HTTP',
    );

    final headers = Map<String, String>.from(response.headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(
        statusCode: response.statusCode,
        data: response.body,
        headers: headers,
      );
    } else {
      final errorMessage = _createErrorMessage(response);

      throw NetworkException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  /// Creates appropriate error message based on status code
  String _createErrorMessage(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'Bad Request: Invalid request parameters';
      case 401:
        return 'Unauthorized: Invalid credentials or API key';
      case 403:
        return 'Forbidden: Access denied';
      case 404:
        return 'Not Found: Requested resource not found';
      case 408:
        return 'Request Timeout: Server did not receive complete request';
      case 429:
        return 'Rate Limited: Too many requests, please try again later';
      case 500:
        return 'Internal Server Error: Server encountered an error';
      case 502:
        return 'Bad Gateway: Invalid response from upstream server';
      case 503:
        return 'Service Unavailable: Server temporarily unavailable';
      case 504:
        return 'Gateway Timeout: Upstream server timeout';
      default:
        return 'HTTP Error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
    }
  }

  /// Closes the underlying HTTP client
  void close() {
    _client.close();
  }
}

/// Extension to check if NetworkException is a client error
extension NetworkExceptionExtension on NetworkException {
  /// Whether this is a client error (4xx status codes)
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Whether this is a server error (5xx status codes)
  bool get isServerError =>
      statusCode != null && statusCode! >= 500 && statusCode! < 600;
}
