import '../base_exception.dart';

/// Exception thrown when API response processing fails
class ApiException extends BaseException {
  /// HTTP status code from the API response
  final int? statusCode;

  /// Creates an API exception
  ///
  /// [message] - Description of the API error
  /// [statusCode] - HTTP status code (optional)
  ApiException(super.message, {this.statusCode})
      : super(severity: ExceptionSeverity.high);

  @override
  String toString() => statusCode != null
      ? 'ApiException: $message (Status: $statusCode)'
      : 'ApiException: $message';
}
