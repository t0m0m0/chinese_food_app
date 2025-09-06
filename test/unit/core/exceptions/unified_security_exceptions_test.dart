import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';
import 'package:chinese_food_app/core/exceptions/unified_security_exception.dart';

void main() {
  group('UnifiedSecurityException', () {
    test('should create security exception with context', () {
      // Arrange
      const message = 'Security error';
      const context = 'API key validation';

      // Act
      final exception = UnifiedSecurityException(
        message,
        context: context,
      );

      // Assert
      expect(exception.message, equals(message));
      expect(exception.context, equals(context));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create API key not found exception', () {
      // Arrange
      const keyType = 'HOTPEPPER_API_KEY';

      // Act
      final exception = UnifiedSecurityException.apiKeyNotFound(keyType);

      // Assert
      expect(exception.message, contains(keyType));
      expect(exception.message, contains('が設定されていません'));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create API key access exception', () {
      // Arrange
      const keyType = 'HOTPEPPER_API_KEY';
      const errorMessage = 'Access denied';

      // Act
      final exception = UnifiedSecurityException.apiKeyAccess(
        keyType,
        errorMessage,
      );

      // Assert
      expect(exception.message, contains(keyType));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create secure storage exception', () {
      // Arrange
      const operation = 'read';
      const errorMessage = 'Storage access failed';

      // Act
      final exception = UnifiedSecurityException.secureStorage(
        operation,
        errorMessage,
      );

      // Assert
      expect(exception.message, contains('セキュアストレージ'));
      expect(exception.message, contains(operation));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create environment config exception', () {
      // Arrange
      const errorMessage = 'Missing required config';

      // Act
      final exception =
          UnifiedSecurityException.environmentConfig(errorMessage);

      // Assert
      expect(exception.message, contains('環境設定エラー'));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should have correct toString output with context', () {
      // Arrange
      const message = 'Test security error';
      const context = 'Test context';
      final exception = UnifiedSecurityException(
        message,
        context: context,
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result,
          equals('セキュリティエラー: $message (詳細: $context)'));
    });

    test('should have correct toString output without context', () {
      // Arrange
      const message = 'Test security error';
      final exception = UnifiedSecurityException(message);

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('セキュリティエラー: $message'));
    });
  });
}
