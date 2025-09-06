import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';
import 'package:chinese_food_app/core/exceptions/unified_network_exception.dart';
import 'package:chinese_food_app/core/exceptions/unified_exceptions.dart';

void main() {
  group('UnifiedNetworkException', () {
    test('should create network exception with status code', () {
      // Arrange
      const message = 'Network error';
      const statusCode = 404;

      // Act
      final exception = UnifiedNetworkException(
        message,
        statusCode: statusCode,
        errorType: NetworkErrorType.httpError,
      );

      // Assert
      expect(exception.message, equals(message));
      expect(exception.statusCode, equals(statusCode));
      expect(exception.errorType, equals(NetworkErrorType.httpError));
      expect(exception.severity, equals(ExceptionSeverity.high));
    });

    test('should create api exception with unified network exception', () {
      // Arrange
      const message = 'API error';
      const statusCode = 500;

      // Act
      final exception = UnifiedNetworkException.api(
        message,
        statusCode: statusCode,
      );

      // Assert
      expect(exception.message, equals(message));
      expect(exception.statusCode, equals(statusCode));
      expect(exception.errorType, equals(NetworkErrorType.apiError));
      expect(exception.severity, equals(ExceptionSeverity.high));
    });

    test('should create connection timeout exception', () {
      // Arrange
      const message = 'Connection timeout';

      // Act
      final exception = UnifiedNetworkException.timeout(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.statusCode, isNull);
      expect(exception.errorType, equals(NetworkErrorType.timeout));
      expect(exception.severity, equals(ExceptionSeverity.medium));
    });

    test('should have correct toString output', () {
      // Arrange
      const message = 'Test error';
      const statusCode = 403;
      final exception = UnifiedNetworkException(
        message,
        statusCode: statusCode,
        errorType: NetworkErrorType.httpError,
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(
          result,
          equals(
              'UnifiedNetworkException: $message (Status: $statusCode, Type: httpError)'));
    });
  });

  group('NetworkErrorType', () {
    test('should have all required error types', () {
      // Assert
      expect(NetworkErrorType.values.length, equals(5));
      expect(
          NetworkErrorType.values.contains(NetworkErrorType.httpError), isTrue);
      expect(
          NetworkErrorType.values.contains(NetworkErrorType.apiError), isTrue);
      expect(
          NetworkErrorType.values.contains(NetworkErrorType.timeout), isTrue);
      expect(NetworkErrorType.values.contains(NetworkErrorType.connectionError),
          isTrue);
      expect(
          NetworkErrorType.values.contains(NetworkErrorType.unknown), isTrue);
    });
  });
}
