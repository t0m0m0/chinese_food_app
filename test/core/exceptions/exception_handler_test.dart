import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';
import 'package:chinese_food_app/core/exceptions/exception_handler.dart';

void main() {
  group('ExceptionHandler', () {
    late ExceptionHandler handler;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      handler = ExceptionHandler(logger: mockLogger);
    });

    test('should handle AppException and return formatted result', () {
      // Arrange
      final exception =
          ValidationException('Invalid email format', fieldName: 'email');

      // Act
      final result = handler.handle(exception);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.userMessage, isNotEmpty);
      expect(result.exception, equals(exception));
      expect(result.severity, equals(ExceptionSeverity.medium));
    });

    test('should handle generic Exception and wrap in AppException', () {
      // Arrange
      final exception = FormatException('Invalid format');

      // Act
      final result = handler.handle(exception);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.exception, isA<AppException>());
      expect(result.exception!.message, contains('Invalid format'));
      expect(result.severity, equals(ExceptionSeverity.medium));
    });

    test('should log exception details when handling', () {
      // Arrange
      final exception = NetworkException('Connection failed', statusCode: 500);

      // Act
      handler.handle(exception);

      // Assert
      expect(mockLogger.loggedExceptions, hasLength(1));
      expect(mockLogger.loggedExceptions.first, equals(exception));
    });

    test('should return success result for successful operations', () {
      // Arrange
      const data = 'Success data';

      // Act
      final result = handler.success(data);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(data));
      expect(result.exception, isNull);
      expect(result.userMessage, isEmpty);
    });

    test('should provide different user messages based on exception type', () {
      // Arrange
      final networkException = NetworkException('API failed');
      final validationException = ValidationException('Invalid input');

      // Act
      final networkResult = handler.handle(networkException);
      final validationResult = handler.handle(validationException);

      // Assert
      expect(networkResult.userMessage,
          isNot(equals(validationResult.userMessage)));
      expect(networkResult.userMessage,
          contains('ネットワーク')); // Network-related message
      expect(validationResult.userMessage,
          contains('入力')); // Input-related message
    });
  });

  group('ExceptionResult', () {
    test('should create success result correctly', () {
      // Arrange
      const data = 'test data';

      // Act
      final result = ExceptionResult.success(data);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(data));
      expect(result.exception, isNull);
      expect(result.userMessage, isEmpty);
    });

    test('should create failure result correctly', () {
      // Arrange
      final exception = AppException('Test error');
      const userMessage = 'User friendly message';

      // Act
      final result = ExceptionResult.failure(exception, userMessage);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals(userMessage));
      expect(result.data, isNull);
    });
  });
}

// テスト用のモックロガー
class MockLogger implements ExceptionLogger {
  final List<Exception> loggedExceptions = [];

  @override
  void logException(Exception exception, {ExceptionSeverity? severity}) {
    loggedExceptions.add(exception);
  }
}
