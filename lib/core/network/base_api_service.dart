import 'dart:convert';
import 'dart:developer' as developer;

import '../exceptions/unified_exceptions_export.dart';
import 'api_response.dart';
import 'app_http_client.dart';

/// Base API service providing common functionality for API communication
///
/// This class serves as a foundation for all API service implementations,
/// providing standardized methods for JSON handling, error processing,
/// and response validation.
///
/// Features:
/// - Automatic JSON serialization/deserialization
/// - Type-safe response handling
/// - Unified error processing
/// - Request/response logging
/// - Common HTTP patterns
///
/// Example usage:
/// ```dart
/// class UserApiService extends BaseApiService {
///   UserApiService(super.httpClient);
///
///   Future<List<User>> getUsers() async {
///     return getAndParse<List<User>>(
///       '/api/users',
///       (json) => (json as List).map((item) => User.fromJson(item)).toList(),
///     );
///   }
/// }
/// ```
abstract class BaseApiService {
  final AppHttpClient _httpClient;

  /// Creates a BaseApiService instance
  ///
  /// [httpClient] - HTTP client for network communication
  BaseApiService(this._httpClient);

  /// Protected access to the HTTP client for subclasses
  AppHttpClient get httpClient => _httpClient;

  /// Performs GET request and parses JSON response
  ///
  /// [path] - API endpoint path
  /// [parser] - Function to parse JSON data to desired type
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns parsed data of type [T]
  /// Throws [UnifiedNetworkException] on API or network errors
  Future<T> getAndParse<T>(
    String path,
    T Function(dynamic json) parser, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('GET $path', name: 'API');

      final response = await _httpClient.get(
        path,
        headers: headers,
        queryParameters: queryParameters,
      );

      return _parseResponse(response, parser);
    } catch (e) {
      _logError('GET $path failed', e);
      rethrow;
    }
  }

  /// Performs POST request and parses JSON response
  ///
  /// [path] - API endpoint path
  /// [parser] - Function to parse JSON data to desired type
  /// [body] - Request body (will be JSON encoded if not string)
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns parsed data of type [T]
  /// Throws [UnifiedNetworkException] on API or network errors
  Future<T> postAndParse<T>(
    String path,
    T Function(dynamic json) parser, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('POST $path', name: 'API');

      final response = await _httpClient.post(
        path,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
      );

      return _parseResponse(response, parser);
    } catch (e) {
      _logError('POST $path failed', e);
      rethrow;
    }
  }

  /// Performs PUT request and parses JSON response
  ///
  /// [path] - API endpoint path
  /// [parser] - Function to parse JSON data to desired type
  /// [body] - Request body (will be JSON encoded if not string)
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns parsed data of type [T]
  /// Throws [UnifiedNetworkException] on API or network errors
  Future<T> putAndParse<T>(
    String path,
    T Function(dynamic json) parser, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('PUT $path', name: 'API');

      final response = await _httpClient.put(
        path,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
      );

      return _parseResponse(response, parser);
    } catch (e) {
      _logError('PUT $path failed', e);
      rethrow;
    }
  }

  /// Performs DELETE request and parses JSON response
  ///
  /// [path] - API endpoint path
  /// [parser] - Function to parse JSON data to desired type
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns parsed data of type [T]
  /// Throws [UnifiedNetworkException] on API or network errors
  Future<T> deleteAndParse<T>(
    String path,
    T Function(dynamic json) parser, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('DELETE $path', name: 'API');

      final response = await _httpClient.delete(
        path,
        headers: headers,
        queryParameters: queryParameters,
      );

      return _parseResponse(response, parser);
    } catch (e) {
      _logError('DELETE $path failed', e);
      rethrow;
    }
  }

  /// Performs GET request without parsing (returns raw response)
  ///
  /// [path] - API endpoint path
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns raw [ApiResponse]
  /// Throws [UnifiedNetworkException] on network errors
  Future<ApiResponse> getRaw(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('GET $path (raw)', name: 'API');

      return await _httpClient.get(
        path,
        headers: headers,
        queryParameters: queryParameters,
      );
    } catch (e) {
      _logError('GET $path (raw) failed', e);
      rethrow;
    }
  }

  /// Performs POST request without parsing (returns raw response)
  ///
  /// [path] - API endpoint path
  /// [body] - Request body
  /// [headers] - Additional request headers
  /// [queryParameters] - URL query parameters
  ///
  /// Returns raw [ApiResponse]
  /// Throws [UnifiedNetworkException] on network errors
  Future<ApiResponse> postRaw(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      developer.log('POST $path (raw)', name: 'API');

      return await _httpClient.post(
        path,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
      );
    } catch (e) {
      _logError('POST $path (raw) failed', e);
      rethrow;
    }
  }

  /// Parses API response and handles errors
  T _parseResponse<T>(ApiResponse response, T Function(dynamic) parser) {
    try {
      // For empty responses, return null as JSON if parser can handle it
      if (response.isEmpty) {
        developer.log('Empty response received', name: 'API');
        return parser(null);
      }

      // Parse JSON data with large response monitoring
      if (response.data.length > 1024 * 1024) {
        // 1MB
        developer.log(
          'Large response detected: ${response.data.length} bytes',
          name: 'API',
          level: 900, // WARNING level
        );
      }

      final jsonData = jsonDecode(response.data);
      developer.log('Response parsed successfully', name: 'API');

      return parser(jsonData);
    } on FormatException catch (e) {
      throw UnifiedNetworkException.api(
        'Invalid JSON response: ${e.message}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is UnifiedNetworkException) rethrow;

      throw UnifiedNetworkException.api(
        'Response parsing failed: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Logs API errors with context
  void _logError(String operation, Object error) {
    developer.log(
      '$operation: $error',
      name: 'API',
      level: 1000, // ERROR level
      error: error,
    );
  }

  /// Validates that required fields are present in JSON data
  ///
  /// [json] - JSON object to validate
  /// [requiredFields] - List of required field names
  ///
  /// Throws [UnifiedNetworkException] if any required field is missing
  void validateRequiredFields(
      Map<String, dynamic> json, List<String> requiredFields) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      throw UnifiedNetworkException.api(
        'Missing required fields: ${missingFields.join(', ')}',
      );
    }
  }

  /// Safely extracts string value from JSON
  ///
  /// [json] - JSON object
  /// [key] - Field key
  /// [defaultValue] - Default value if field is missing
  ///
  /// Returns string value or default
  String getStringValue(Map<String, dynamic> json, String key,
      [String defaultValue = '']) {
    final value = json[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safely extracts integer value from JSON
  ///
  /// [json] - JSON object
  /// [key] - Field key
  /// [defaultValue] - Default value if field is missing
  ///
  /// Returns integer value or default
  int getIntValue(Map<String, dynamic> json, String key,
      [int defaultValue = 0]) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.round();

    return defaultValue;
  }

  /// Safely extracts double value from JSON
  ///
  /// [json] - JSON object
  /// [key] - Field key
  /// [defaultValue] - Default value if field is missing
  ///
  /// Returns double value or default
  double getDoubleValue(Map<String, dynamic> json, String key,
      [double defaultValue = 0.0]) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  /// Safely extracts boolean value from JSON
  ///
  /// [json] - JSON object
  /// [key] - Field key
  /// [defaultValue] - Default value if field is missing
  ///
  /// Returns boolean value or default
  bool getBoolValue(Map<String, dynamic> json, String key,
      [bool defaultValue = false]) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;

    return defaultValue;
  }

  /// Safely extracts list value from JSON
  ///
  /// [json] - JSON object
  /// [key] - Field key
  /// [defaultValue] - Default value if field is missing
  ///
  /// Returns list value or default
  List<T> getListValue<T>(Map<String, dynamic> json, String key,
      [List<T> defaultValue = const []]) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is List<T>) return value;
    if (value is List) return value.cast<T>();

    return defaultValue;
  }

  /// Closes the underlying HTTP client
  void dispose() {
    _httpClient.close();
  }
}
