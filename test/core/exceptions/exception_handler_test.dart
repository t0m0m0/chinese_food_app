import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart';
import 'package:chinese_food_app/core/exceptions/handlers/exception_handler.dart';

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
      final exception = const FormatException('Invalid format');

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

    group('Convenience Methods', () {
      test('execute should handle sync exceptions', () {
        // Act
        final result = handler.execute<int>(() {
          throw ValidationException('Sync error');
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<ValidationException>());
        expect(result.userMessage, contains('入力'));
      });

      test('execute should return success for successful operations', () {
        // Act
        final result = handler.execute<String>(() {
          return 'Success result';
        });

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals('Success result'));
        expect(result.exception, isNull);
      });

      test('executeAsync should handle async exceptions', () async {
        // Act
        final result = await handler.executeAsync<String>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          throw NetworkException('Async network error', statusCode: 500);
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<NetworkException>());
        expect(result.userMessage, contains('ネットワーク'));
      });

      test('executeAsync should return success for successful async operations',
          () async {
        // Act
        final result = await handler.executeAsync<int>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        });

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(42));
        expect(result.exception, isNull);
      });

      test('should handle non-Exception errors in execute', () {
        // Act
        final result = handler.execute<String>(() {
          throw 'String error'; // Non-Exception error
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<AppException>());
        expect(result.exception!.message, contains('String error'));
      });

      test('should handle non-Exception errors in executeAsync', () async {
        // Act
        final result = await handler.executeAsync<String>(() async {
          throw 'Async string error'; // Non-Exception error
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<AppException>());
        expect(result.exception!.message, contains('Async string error'));
      });

      test('should preserve stack trace in execute', () {
        // Act
        final result = handler.execute<String>(() {
          throw const FormatException('Format error');
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<AppException>());
        expect(result.exception!.cause, isA<FormatException>());
        expect(result.exception!.stackTrace, isNotNull);
      });

      test('should preserve stack trace in executeAsync', () async {
        // Act
        final result = await handler.executeAsync<String>(() async {
          throw TimeoutException('Timeout error', const Duration(seconds: 1));
        });

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exception, isA<AppException>());
        expect(result.exception!.cause, isA<TimeoutException>());
        expect(result.exception!.stackTrace, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle empty error messages', () {
        // Arrange
        final exception = AppException('');

        // Act
        final result = handler.handle(exception);

        // Assert
        expect(result.userMessage, isNotEmpty); // Should have fallback message
        expect(result.userMessage, equals('予期しないエラーが発生しました。'));
      });

      test('should handle null safety correctly for ValidationException', () {
        // Arrange
        final exception = ValidationException('Test', fieldName: null);

        // Act & Assert
        expect(exception.fieldName, isNull);
        expect(exception.toString(), equals('ValidationException: Test'));
      });

      test('should handle null safety correctly for NetworkException', () {
        // Arrange
        final exception = NetworkException('Network error', statusCode: null);

        // Act & Assert
        expect(exception.statusCode, isNull);
        expect(exception.toString(), equals('NetworkException: Network error'));
      });

      test('should handle null safety correctly for DatabaseException', () {
        // Arrange
        final exception =
            DatabaseException('DB error', operation: null, table: null);

        // Act & Assert
        expect(exception.operation, isNull);
        expect(exception.table, isNull);
        expect(exception.toString(), equals('DatabaseException: DB error'));
      });

      test('should handle very long error messages', () {
        // Arrange
        final longMessage = 'A' * 1000; // 1000 character message
        final exception = AppException(longMessage);

        // Act
        final result = handler.handle(exception);

        // Assert
        expect(result.exception!.message, equals(longMessage));
        expect(result.userMessage, isNotEmpty);
      });

      test('should handle exception with null cause', () {
        // Arrange
        final exception = AppException('Test message', cause: null);

        // Act & Assert
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('AppException: Test message'));
        expect(exception.toString(), isNot(contains('Caused by')));
      });

      test('should handle exception with null stack trace', () {
        // Arrange
        final exception = AppException('Test message', stackTrace: null);

        // Act & Assert
        expect(exception.stackTrace, isNull);
        expect(exception.message, equals('Test message'));
      });

      test('should handle multiple levels of exception chaining', () {
        // Arrange
        final rootCause = const FormatException('Root cause');
        final middleException =
            AppException('Middle exception', cause: rootCause);
        final topException =
            AppException('Top exception', cause: middleException);

        // Act
        final result = handler.handle(topException);

        // Assert
        expect(result.exception!.cause, equals(middleException));
        expect(result.exception!.cause!.toString(), contains('Caused by'));
        expect(result.exception!.cause!.toString(), contains('Root cause'));
      });
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
