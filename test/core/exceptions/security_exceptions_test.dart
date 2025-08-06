import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/security_exception.dart';
import 'package:chinese_food_app/core/exceptions/base_exception.dart';

void main() {
  group('SecurityException', () {
    test('should create SecurityException with message', () {
      // Arrange
      const message = 'Security violation';

      // Act
      final exception = SecurityException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception.severity, equals(ExceptionSeverity.critical));
      expect(exception.context, isNull);
      expect(exception.originalException, isNull);
    });

    test('should create SecurityException with context and original exception',
        () {
      // Arrange
      const message = 'Security violation';
      const context = 'Authentication module';
      final originalException = Exception('Original error');

      // Act
      final exception = SecurityException(
        message,
        context: context,
        originalException: originalException,
      );

      // Assert
      expect(exception.message, equals(message));
      expect(exception.context, equals(context));
      expect(exception.originalException, equals(originalException));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should format toString without context and original exception', () {
      // Arrange
      const message = 'Security violation';
      final exception = SecurityException(message);

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('SecurityException: $message'));
    });

    test('should format toString with context and original exception', () {
      // Arrange
      const message = 'Security violation';
      const context = 'Auth module';
      final originalException = Exception('Root cause');
      final exception = SecurityException(
        message,
        context: context,
        originalException: originalException,
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('SecurityException: $message'));
      expect(result, contains('(Context: $context)'));
      expect(result, contains('(Caused by: $originalException)'));
    });
  });

  group('APIKeyNotFoundException', () {
    test('should create APIKeyNotFoundException with keyType', () {
      // Arrange
      const keyType = 'HOTPEPPER_API';

      // Act
      final exception = APIKeyNotFoundException(keyType);

      // Assert
      expect(exception.keyType, equals(keyType));
      expect(exception.message, contains(keyType));
      expect(exception.message, contains('APIキーが設定されていません'));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create APIKeyNotFoundException with context', () {
      // Arrange
      const keyType = 'GOOGLE_MAPS_API';
      const context = 'Environment configuration';

      // Act
      final exception = APIKeyNotFoundException(keyType, context: context);

      // Assert
      expect(exception.keyType, equals(keyType));
      expect(exception.context, equals(context));
    });
  });

  group('APIKeyAccessException', () {
    test('should create APIKeyAccessException with keyType and message', () {
      // Arrange
      const keyType = 'HOTPEPPER_API';
      const errorMessage = 'Access denied';

      // Act
      final exception = APIKeyAccessException(keyType, errorMessage);

      // Assert
      expect(exception.keyType, equals(keyType));
      expect(exception.message, contains(keyType));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });
  });

  group('SecureStorageException', () {
    test('should create SecureStorageException with operation and message', () {
      // Arrange
      const operation = 'write';
      const errorMessage = 'Permission denied';

      // Act
      final exception = SecureStorageException(operation, errorMessage);

      // Assert
      expect(exception.operation, equals(operation));
      expect(exception.message, contains('セキュアストレージ$operation エラー'));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });
  });

  group('EnvironmentConfigException', () {
    test('should create EnvironmentConfigException with message', () {
      // Arrange
      const errorMessage = 'Missing configuration';

      // Act
      final exception = EnvironmentConfigException(errorMessage);

      // Assert
      expect(exception.message, contains('環境設定エラー'));
      expect(exception.message, contains(errorMessage));
      expect(exception.severity, equals(ExceptionSeverity.critical));
    });

    test('should create EnvironmentConfigException with context', () {
      // Arrange
      const errorMessage = 'Invalid configuration';
      const context = '.env file';

      // Act
      final exception = EnvironmentConfigException(
        errorMessage,
        context: context,
      );

      // Assert
      expect(exception.context, equals(context));
      expect(exception.message, contains(errorMessage));
    });
  });

  group('Inheritance', () {
    test('should inherit from BaseException', () {
      // Arrange & Act
      final securityException = SecurityException('Test');
      final apiKeyException = APIKeyNotFoundException('TEST_API');
      final accessException = APIKeyAccessException('TEST', 'Access error');
      final storageException = SecureStorageException('read', 'Read error');
      final configException = EnvironmentConfigException('Config error');

      // Assert
      expect(securityException, isA<BaseException>());
      expect(apiKeyException, isA<BaseException>());
      expect(accessException, isA<BaseException>());
      expect(storageException, isA<BaseException>());
      expect(configException, isA<BaseException>());
    });
  });
}
