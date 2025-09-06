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

  /// Rate limit exceeded errors
  rateLimitExceeded,

  /// Service maintenance or unavailable errors
  maintenance,

  /// Authentication/authorization failures
  unauthorized,

  /// SSL/TLS certificate errors
  certificateError,

  /// DNS resolution failures
  dnsError,

  /// Unknown or unspecified network errors
  unknown,
}
