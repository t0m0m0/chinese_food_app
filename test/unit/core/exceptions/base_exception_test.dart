import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';

void main() {
  group('BaseException', () {
    group('Creation and Basic Properties', () {
      test('should create BaseException with message', () {
        // Arrange
        const message = 'Test error message';

        // Act
        final exception = BaseException(message);

        // Assert
        expect(exception.message, equals(message));
        expect(exception.severity, equals(ExceptionSeverity.medium));
        expect(exception.timestamp, isA<DateTime>());
        expect(exception.cause, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('should create BaseException with all parameters', () {
        // Arrange
        const message = 'Test error message';
        const severity = ExceptionSeverity.high;
        final cause = Exception('Root cause');
        final stackTrace = StackTrace.current;

        // Act
        final exception = BaseException(
          message,
          severity: severity,
          cause: cause,
          stackTrace: stackTrace,
        );

        // Assert
        expect(exception.message, equals(message));
        expect(exception.severity, equals(severity));
        expect(exception.cause, equals(cause));
        expect(exception.stackTrace, equals(stackTrace));
        expect(exception.timestamp, isA<DateTime>());
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when message and severity are same', () {
        // Arrange
        final exception1 =
            BaseException('Same message', severity: ExceptionSeverity.high);
        final exception2 =
            BaseException('Same message', severity: ExceptionSeverity.high);

        // Act & Assert
        expect(exception1, equals(exception2));
        expect(exception1.hashCode, equals(exception2.hashCode));
      });

      test('should not be equal when message differs', () {
        // Arrange
        final exception1 = BaseException('Message 1');
        final exception2 = BaseException('Message 2');

        // Act & Assert
        expect(exception1, isNot(equals(exception2)));
        expect(exception1.hashCode, isNot(equals(exception2.hashCode)));
      });

      test('should not be equal when severity differs', () {
        // Arrange
        final exception1 =
            BaseException('Same message', severity: ExceptionSeverity.low);
        final exception2 =
            BaseException('Same message', severity: ExceptionSeverity.high);

        // Act & Assert
        expect(exception1, isNot(equals(exception2)));
        expect(exception1.hashCode, isNot(equals(exception2.hashCode)));
      });
    });

    group('String Representation', () {
      test('should return formatted string without cause', () {
        // Arrange
        final exception = BaseException('Test message');

        // Act
        final result = exception.toString();

        // Assert
        expect(result, equals('BaseException: Test message'));
      });

      test('should return formatted string with cause', () {
        // Arrange
        final cause = Exception('Root cause');
        final exception = BaseException('Test message', cause: cause);

        // Act
        final result = exception.toString();

        // Assert
        expect(
            result,
            equals(
                'BaseException: Test message\nCaused by: Exception: Root cause'));
      });
    });

    group('Inheritance Support', () {
      test('should work as base class for other exceptions', () {
        // Arrange & Act
        final customException = _TestCustomException('Custom error');

        // Assert
        expect(customException, isA<BaseException>());
        expect(customException.message, equals('Custom error'));
        expect(customException.severity, equals(ExceptionSeverity.critical));
      });
    });
  });

  group('ExceptionSeverity Enum', () {
    test('should have all required severity levels', () {
      // Act & Assert
      expect(ExceptionSeverity.values, hasLength(4));
      expect(ExceptionSeverity.values, contains(ExceptionSeverity.low));
      expect(ExceptionSeverity.values, contains(ExceptionSeverity.medium));
      expect(ExceptionSeverity.values, contains(ExceptionSeverity.high));
      expect(ExceptionSeverity.values, contains(ExceptionSeverity.critical));
    });

    test('should maintain order from low to critical', () {
      // Act & Assert
      expect(ExceptionSeverity.low.index,
          lessThan(ExceptionSeverity.medium.index));
      expect(ExceptionSeverity.medium.index,
          lessThan(ExceptionSeverity.high.index));
      expect(ExceptionSeverity.high.index,
          lessThan(ExceptionSeverity.critical.index));
    });
  });
}

// Test helper class to verify inheritance
class _TestCustomException extends BaseException {
  _TestCustomException(super.message)
      : super(severity: ExceptionSeverity.critical);
}
