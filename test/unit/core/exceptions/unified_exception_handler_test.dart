import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';
import 'package:chinese_food_app/core/exceptions/unified_network_exception.dart';
import 'package:chinese_food_app/core/exceptions/unified_security_exception.dart';
import 'package:chinese_food_app/core/exceptions/handlers/unified_exception_handler.dart';
import 'package:chinese_food_app/core/exceptions/domain/validation_exception.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/database_exception.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/location_exception.dart';

void main() {
  group('UnifiedExceptionHandler', () {
    late UnifiedExceptionHandler handler;

    setUp(() {
      handler = UnifiedExceptionHandler();
    });

    test('should handle UnifiedNetworkException with correct user message', () {
      // Arrange
      final exception = UnifiedNetworkException.api(
        'API error',
        statusCode: 404,
      );

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('ネットワークエラーが発生しました。しばらくしてからお試しください。'));
      expect(result.severity, equals(ExceptionSeverity.high));
    });

    test('should handle UnifiedSecurityException with correct user message',
        () {
      // Arrange
      final exception =
          UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('認証エラーが発生しました。設定を確認してください。'));
      expect(result.severity, equals(ExceptionSeverity.critical));
    });

    test('should handle ValidationException with correct user message', () {
      // Arrange
      final exception =
          ValidationException('Invalid input', fieldName: 'email');

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('入力内容に誤りがあります。確認してください。'));
      expect(result.severity, equals(ExceptionSeverity.medium));
    });

    test('should handle DatabaseException with correct user message', () {
      // Arrange
      final exception =
          DatabaseException('Database error', operation: 'INSERT');

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('データの保存に失敗しました。'));
      expect(result.severity, equals(ExceptionSeverity.critical));
    });

    test('should handle LocationException with permission denied message', () {
      // Arrange
      final exception = LocationException(
        'Permission denied',
        reason: LocationExceptionReason.permissionDenied,
      );

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('位置情報の利用許可が必要です。'));
      expect(result.severity, equals(ExceptionSeverity.medium));
    });

    test('should handle generic Exception with conversion to BaseException',
        () {
      // Arrange
      final exception = Exception('Generic error');

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, isA<BaseException>());
      expect(result.userMessage, equals('予期しないエラーが発生しました。'));
    });

    test('should create successful result', () {
      // Arrange
      const data = 'Test data';

      // Act
      final result = handler.success(data);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(data));
      expect(result.exception, isNull);
      expect(result.userMessage, isEmpty);
    });

    test('should execute operation with success', () {
      // Arrange
      const expectedData = 'Success data';

      // Act
      final result = handler.execute(() => expectedData);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(expectedData));
    });

    test('should execute operation with exception handling', () {
      // Arrange
      final exception = UnifiedNetworkException.timeout('Timeout error');

      // Act
      final result = handler.execute<String>(() => throw exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('タイムアウトが発生しました。ネットワーク状況を確認してください。'));
    });

    test('should execute async operation with success', () async {
      // Arrange
      const expectedData = 'Async success data';

      // Act
      final result = await handler.executeAsync(() async => expectedData);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(expectedData));
    });

    test('should execute async operation with exception handling', () async {
      // Arrange
      final exception = UnifiedSecurityException.apiKeyNotFound('TEST_KEY');

      // Act
      final result =
          await handler.executeAsync<String>(() async => throw exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('認証エラーが発生しました。設定を確認してください。'));
    });

    test('should handle rate limit exception with specific user message', () {
      // Arrange
      final exception = UnifiedNetworkException.rateLimitExceeded(
        'Rate limit exceeded',
        statusCode: 429,
      );

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('API利用制限に達しました。しばらくしてからお試しください。'));
      expect(result.severity, equals(ExceptionSeverity.high));
    });

    test('should handle maintenance exception with specific user message', () {
      // Arrange
      final exception = UnifiedNetworkException.maintenance(
        'Service under maintenance',
      );

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('サービスがメンテナンス中です。しばらくお待ちください。'));
      expect(result.severity, equals(ExceptionSeverity.medium));
    });

    test('should handle unauthorized exception with specific user message', () {
      // Arrange
      final exception = UnifiedNetworkException.unauthorized(
        'Unauthorized access',
        statusCode: 401,
      );

      // Act
      final result = handler.handle<String>(exception);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.exception, equals(exception));
      expect(result.userMessage, equals('認証が必要です。ログイン状態を確認してください。'));
      expect(result.severity, equals(ExceptionSeverity.high));
    });
  });
}
