/// Network error types for unified network exception handling
enum NetworkErrorType {
  /// HTTP-related errors (4xx, 5xx status codes)
  httpError,

  /// API-specific errors (business logic failures)
  apiError,

  /// Connection timeout errors
  timeout,

  /// Connection or network connectivity errors
  connectionError,

  /// Unknown or unspecified network errors
  unknown,
}
