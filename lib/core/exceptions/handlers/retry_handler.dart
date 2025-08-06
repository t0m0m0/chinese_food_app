import 'dart:async';
import 'dart:math' as math;
import 'domain_exceptions.dart';
import 'exception_handler.dart';

/// Handler for retry logic with configurable retry policies
class RetryHandler {
  final ExceptionHandler _exceptionHandler;

  /// Maximum delay for exponential backoff (30 seconds)
  static const int _maxDelayMs = 30000;

  /// Creates a retry handler with optional exception handler
  RetryHandler({ExceptionHandler? exceptionHandler})
      : _exceptionHandler = exceptionHandler ?? ExceptionHandler();

  /// Execute an operation with retry logic
  Future<ExceptionResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool useExponentialBackoff = false,
  }) async {
    int attempt = 0;
    Duration currentDelay = retryDelay;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        final result = await operation();
        return _exceptionHandler.success(result);
      } catch (e, stackTrace) {
        final exception = e is Exception ? e : Exception(e.toString());

        // Don't retry on validation errors
        if (exception is ValidationException) {
          return _exceptionHandler.handle(exception, stackTrace);
        }

        // If this was the last attempt, return the failure
        if (attempt >= maxAttempts) {
          return _exceptionHandler.handle(exception, stackTrace);
        }

        // Wait before retrying (except for the last failed attempt)
        if (attempt < maxAttempts) {
          await Future.delayed(currentDelay);

          if (useExponentialBackoff) {
            final newDelayMs = currentDelay.inMilliseconds * 2;
            currentDelay = Duration(
              milliseconds: math.min(newDelayMs, _maxDelayMs),
            );
          }
        }
      }
    }

    // Should never reach here, but just in case
    return _exceptionHandler.handle(Exception('Max attempts reached'), null);
  }
}
