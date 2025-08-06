import '../base_exception.dart';

/// Exception thrown when input validation fails
class ValidationException extends BaseException {
  /// The name of the field that failed validation (optional)
  final String? fieldName;

  /// Creates a validation exception
  ///
  /// [message] - Description of the validation error
  /// [fieldName] - Name of the field that failed validation (optional)
  ValidationException(super.message, {this.fieldName})
      : super(severity: ExceptionSeverity.medium);

  @override
  String toString() => fieldName != null
      ? 'ValidationException: $message (Field: $fieldName)'
      : 'ValidationException: $message';
}
