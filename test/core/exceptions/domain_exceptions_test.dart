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
      expect(exception.toString(), equals('ValidationException: $message (Field: $fieldName)'));
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
  });
}

