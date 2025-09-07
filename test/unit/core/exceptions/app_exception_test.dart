import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';

void main() {
  group('AppException', () {
    test('should create exception with message', () {
      // Arrange
      const message = 'Test error message';

      // Act
      final exception = AppException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.toString(), contains(message));
    });

    test('should create exception with severity level', () {
      // Arrange
      const message = 'Critical error';
      const severity = ExceptionSeverity.critical;

      // Act
      final exception = AppException(message, severity: severity);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.severity, equals(severity));
    });

    test('should have default severity as medium', () {
      // Arrange
      const message = 'Default severity test';

      // Act
      final exception = AppException(message);

      // Assert
      expect(exception.severity, equals(ExceptionSeverity.medium));
    });

    test('should include timestamp when created', () {
      // Arrange
      const message = 'Timestamp test';
      final beforeCreation = DateTime.now();

      // Act
      final exception = AppException(message);
      final afterCreation = DateTime.now();

      // Assert
      expect(
          exception.timestamp
              .isAfter(beforeCreation.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          exception.timestamp
              .isBefore(afterCreation.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('should support exception chaining with cause', () {
      // Arrange
      const message = 'Wrapper exception';
      final causeException = const FormatException('Original cause');

      // Act
      final exception = AppException(message, cause: causeException);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.cause, equals(causeException));
    });

    test('should support stack trace preservation', () {
      // Arrange
      const message = 'Exception with stack trace';
      final stackTrace = StackTrace.current;

      // Act
      final exception = AppException(message, stackTrace: stackTrace);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('should format toString with cause information', () {
      // Arrange
      const message = 'Main exception';
      final causeException = const FormatException('Invalid argument');

      // Act
      final exception = AppException(message, cause: causeException);

      // Assert
      expect(exception.toString(), contains(message));
      expect(exception.toString(), contains('Caused by'));
      expect(exception.toString(), contains('Invalid argument'));
    });

    test('should format toString without cause when cause is null', () {
      // Arrange
      const message = 'Simple exception';

      // Act
      final exception = AppException(message);

      // Assert
      expect(exception.toString(), equals('AppException: $message'));
      expect(exception.toString(), isNot(contains('Caused by')));
    });
  });
}
