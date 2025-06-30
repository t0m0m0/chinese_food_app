import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';

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
      expect(exception.timestamp.isAfter(beforeCreation.subtract(Duration(seconds: 1))), isTrue);
      expect(exception.timestamp.isBefore(afterCreation.add(Duration(seconds: 1))), isTrue);
    });
  });
}

