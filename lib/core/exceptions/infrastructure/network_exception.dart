import '../base_exception.dart';

/// Exception thrown when network operations fail
class NetworkException extends BaseException {
  /// HTTP status code (if available)
  final int? statusCode;

  /// Creates a network exception
  ///
  /// [message] - Description of the network error
  /// [statusCode] - HTTP status code (optional)
  NetworkException(super.message, {this.statusCode})
      : super(severity: ExceptionSeverity.high);

  @override
  String toString() => statusCode != null
      ? 'NetworkException: $message (Status: $statusCode)'
      : 'NetworkException: $message';
}
