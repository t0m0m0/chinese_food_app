/// Unified API response wrapper
///
/// This class provides a consistent structure for all API responses
/// across the application, enabling standardized response handling
/// and error management.
///
/// Example usage:
/// ```dart
/// final response = await httpClient.get('/api/users');
/// if (response.isSuccess) {
///   final users = jsonDecode(response.data);
/// } else {
///   SecureLogger.error('APIエラー', data: {'statusCode': response.statusCode});
/// }
/// ```
class ApiResponse {
  /// HTTP status code of the response
  final int statusCode;

  /// Response body data (typically JSON string)
  final String data;

  /// HTTP headers from the response
  final Map<String, String> headers;

  /// Error message if the request failed
  final String? errorMessage;

  /// Creates an API response instance
  ///
  /// [statusCode] - HTTP status code (e.g., 200, 404, 500)
  /// [data] - Response body content
  /// [headers] - HTTP response headers
  /// [errorMessage] - Optional error message for failed requests
  const ApiResponse({
    required this.statusCode,
    required this.data,
    this.headers = const {},
    this.errorMessage,
  });

  /// Creates a successful API response
  ///
  /// [statusCode] - HTTP status code (default: 200)
  /// [data] - Response body content
  /// [headers] - HTTP response headers
  factory ApiResponse.success({
    int statusCode = 200,
    required String data,
    Map<String, String> headers = const {},
  }) {
    return ApiResponse(
      statusCode: statusCode,
      data: data,
      headers: headers,
    );
  }

  /// Creates a failed API response
  ///
  /// [statusCode] - HTTP error status code
  /// [errorMessage] - Description of the error
  /// [data] - Optional response body (default: empty)
  /// [headers] - HTTP response headers
  factory ApiResponse.error({
    required int statusCode,
    required String errorMessage,
    String data = '',
    Map<String, String> headers = const {},
  }) {
    return ApiResponse(
      statusCode: statusCode,
      data: data,
      headers: headers,
      errorMessage: errorMessage,
    );
  }

  /// Whether the response indicates success (2xx status codes)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether the response indicates failure
  bool get isFailure => !isSuccess;

  /// Whether this is a client error (4xx status codes)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether this is a server error (5xx status codes)
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Whether this is a redirect response (3xx status codes)
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Content type from headers
  String? get contentType => headers['content-type'] ?? headers['Content-Type'];

  /// Content length from headers
  int? get contentLength {
    final lengthStr = headers['content-length'] ?? headers['Content-Length'];
    return lengthStr != null ? int.tryParse(lengthStr) : null;
  }

  /// Whether the response contains JSON data
  bool get isJson => contentType?.contains('application/json') ?? false;

  /// Whether the response body is empty
  bool get isEmpty => data.isEmpty;

  /// Whether the response body is not empty
  bool get isNotEmpty => data.isNotEmpty;

  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, '
        'dataLength: ${data.length}, '
        'isSuccess: $isSuccess'
        '${errorMessage != null ? ', error: $errorMessage' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse &&
        other.statusCode == statusCode &&
        other.data == data &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(statusCode, data, errorMessage);
  }

  /// Creates a copy of this response with updated values
  ApiResponse copyWith({
    int? statusCode,
    String? data,
    Map<String, String>? headers,
    String? errorMessage,
  }) {
    return ApiResponse(
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
