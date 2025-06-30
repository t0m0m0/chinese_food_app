import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';

void main() {
  group('ValidationException', () {
    test('should create validation exception with field name', () {
      // Arrange
      const message = 'Invalid input format';
      const fieldName = 'email';

      // Act
      final exception = ValidationException(message, fieldName: fieldName);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.fieldName, equals(fieldName));
      expect(exception.severity, equals(ExceptionSeverity.medium));
    });

    test('should create validation exception without field name', () {
      // Arrange
      const message = 'Form validation failed';

      // Act
      final exception = ValidationException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.fieldName, isNull);
    });

    test('should format toString with field name', () {
      // Arrange
      const message = 'Invalid email format';
      const fieldName = 'email';

      // Act
      final exception = ValidationException(message, fieldName: fieldName);

      // Assert
      expect(exception.toString(),
          equals('ValidationException: $message (Field: $fieldName)'));
    });
  });

  group('NetworkException', () {
    test('should create network exception with status code', () {
      // Arrange
      const message = 'Request failed';
      const statusCode = 404;

      // Act
      final exception = NetworkException(message, statusCode: statusCode);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.statusCode, equals(statusCode));
      expect(exception.severity, equals(ExceptionSeverity.high));
    });

    test('should create network exception without status code', () {
      // Arrange
      const message = 'Network timeout';

      // Act
      final exception = NetworkException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.statusCode, isNull);
      expect(exception.severity, equals(ExceptionSeverity.high));
    });
  });

  group('DatabaseException', () {
    test('should create database exception with operation info', () {
      // Arrange
      const message = 'Failed to insert record';
      const operation = 'INSERT';
      const table = 'stores';

      // Act
      final exception = DatabaseException(
        message,
        operation: operation,
        table: table,
      );

      // Assert
      expect(exception.message, equals(message));
      expect(exception.operation, equals(operation));
      expect(exception.table, equals(table));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });
  });

  group('LocationException', () {
    test('should create location exception with permission status', () {
      // Arrange
      const message = 'Location access denied';
      const reason = LocationExceptionReason.permissionDenied;

      // Act
      final exception = LocationException(message, reason: reason);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.reason, equals(reason));
      expect(exception.severity, equals(ExceptionSeverity.medium));
    });

    group('toString() Tests', () {
      test('should format NetworkException toString with status code', () {
        // Arrange
        final exception = NetworkException('API failed', statusCode: 404);

        // Act & Assert
        expect(exception.toString(),
            equals('NetworkException: API failed (Status: 404)'));
      });

      test('should format NetworkException toString without status code', () {
        // Arrange
        final exception = NetworkException('Network timeout');

        // Act & Assert
        expect(
            exception.toString(), equals('NetworkException: Network timeout'));
      });

      test('should format DatabaseException toString with operation and table',
          () {
        // Arrange
        final exception = DatabaseException('Insert failed',
            operation: 'INSERT', table: 'users');

        // Act & Assert
        expect(
            exception.toString(),
            equals(
                'DatabaseException: Insert failed (Operation: INSERT, Table: users)'));
      });

      test('should format DatabaseException toString with operation only', () {
        // Arrange
        final exception =
            DatabaseException('Query failed', operation: 'SELECT');

        // Act & Assert
        expect(exception.toString(),
            equals('DatabaseException: Query failed (Operation: SELECT)'));
      });

      test('should format DatabaseException toString with table only', () {
        // Arrange
        final exception = DatabaseException('Access denied', table: 'admin');

        // Act & Assert
        expect(exception.toString(),
            equals('DatabaseException: Access denied (Table: admin)'));
      });

      test(
          'should format DatabaseException toString without operation or table',
          () {
        // Arrange
        final exception = DatabaseException('Generic DB error');

        // Act & Assert
        expect(exception.toString(),
            equals('DatabaseException: Generic DB error'));
      });

      test('should format LocationException toString with reason', () {
        // Arrange
        final exception = LocationException('GPS failed',
            reason: LocationExceptionReason.timeout);

        // Act & Assert
        expect(
            exception.toString(),
            equals(
                'LocationException: GPS failed (Reason: LocationExceptionReason.timeout)'));
      });

      test('should format LocationException toString with default reason', () {
        // Arrange
        final exception = LocationException('Location error');

        // Act & Assert
        expect(
            exception.toString(),
            equals(
                'LocationException: Location error (Reason: LocationExceptionReason.unknown)'));
      });
    });
  });
}
