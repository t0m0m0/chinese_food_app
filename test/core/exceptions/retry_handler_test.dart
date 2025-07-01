import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/retry_handler.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';

void main() {
  group('RetryHandler', () {
    late RetryHandler retryHandler;

    setUp(() {
      retryHandler = RetryHandler();
    });

    test('should retry operation up to maxAttempts times on NetworkException',
        () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        if (callCount < 3) {
          throw NetworkException('Connection failed');
        }
        return 'Success';
      }

      // Act
      final result = await retryHandler.executeWithRetry(
        operation,
        maxAttempts: 3,
        retryDelay: Duration(milliseconds: 10),
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, 'Success');
      expect(callCount, 3);
    });

    test('should fail after maxAttempts retries', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        throw NetworkException('Connection failed');
      }

      // Act
      final result = await retryHandler.executeWithRetry(
        operation,
        maxAttempts: 2,
        retryDelay: Duration(milliseconds: 10),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.exception, isA<NetworkException>());
      expect(callCount, 2);
    });

    test('should not retry on ValidationException', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        throw ValidationException('Invalid input', fieldName: 'test');
      }

      // Act
      final result = await retryHandler.executeWithRetry(
        operation,
        maxAttempts: 3,
        retryDelay: Duration(milliseconds: 10),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.exception, isA<ValidationException>());
      expect(callCount, 1); // Should not retry
    });

    test('should use exponential backoff when enabled', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      int callCount = 0;

      Future<String> operation() async {
        callCount++;
        if (callCount < 3) {
          throw NetworkException('Connection failed');
        }
        return 'Success';
      }

      // Act
      final result = await retryHandler.executeWithRetry(
        operation,
        maxAttempts: 3,
        retryDelay: Duration(milliseconds: 100),
        useExponentialBackoff: true,
      );

      stopwatch.stop();

      // Assert
      expect(result.isSuccess, true);
      expect(callCount, 3);
      // First retry: 100ms, Second retry: 200ms = 300ms minimum
      expect(stopwatch.elapsedMilliseconds, greaterThan(250));
    });
  });
}
