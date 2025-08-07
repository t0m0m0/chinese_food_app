import '../exceptions/base_exception.dart';

/// A type-safe Result pattern for handling success and failure cases
///
/// This sealed class provides exhaustive pattern matching for operations
/// that can either succeed with data of type [T] or fail with an exception.
///
/// Example usage:
/// ```dart
/// Result<String> fetchData() {
///   try {
///     final data = someOperation();
///     return Success(data);
///   } catch (e) {
///     return Failure(BaseException('Operation failed: $e'));
///   }
/// }
///
/// final result = fetchData();
/// switch (result) {
///   case Success<String>():
///     SecureLogger.info('処理完了', data: {'result': result.data});
///   case Failure<String>():
///     SecureLogger.error('処理エラー', error: result.exception);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Whether this Result represents a successful operation
  bool get isSuccess => this is Success<T>;

  /// Whether this Result represents a failed operation
  bool get isFailure => this is Failure<T>;

  /// Returns the data if this is a Success, null otherwise
  T? get dataOrNull => switch (this) {
        Success<T> success => success.data,
        Failure<T> _ => null,
      };

  /// Returns the exception if this is a Failure, null otherwise
  BaseException? get exceptionOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> failure => failure.exception,
      };
}

/// Represents a successful operation with data of type [T]
final class Success<T> extends Result<T> {
  /// The successful result data
  final T data;

  /// Creates a Success result with the given data
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation with an exception
final class Failure<T> extends Result<T> {
  /// The exception that caused the failure
  final BaseException exception;

  /// Creates a Failure result with the given exception
  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}
