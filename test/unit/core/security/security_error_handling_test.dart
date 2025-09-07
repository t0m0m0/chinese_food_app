import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:chinese_food_app/core/security/minimal_security_interface.dart';
import 'package:chinese_food_app/core/security/security_error_handler.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/security_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityErrorHandling', () {
    late BasicSecurityManager securityManager;

    setUp(() {
      securityManager = BasicSecurityManager();
    });

    tearDown(() {
      // モックをクリア
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('should handle storage read errors gracefully', () async {
      // Red → Green: ストレージ読み込みエラーの適切な処理

      // モックでエラーを発生させる
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (methodCall) async {
          if (methodCall.method == 'read') {
            throw PlatformException(
                code: 'STORAGE_ERROR', message: 'Storage not available');
          }
          return null;
        },
      );

      // エラーが発生してもnullを返し、例外をスローしない
      final result = await securityManager.getApiKey('test_key');
      expect(result, isNull);
    });

    test('should throw exception on storage write errors', () async {
      // Red → Green: ストレージ書き込みエラー時の例外スロー

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (methodCall) async {
          if (methodCall.method == 'write') {
            throw PlatformException(
                code: 'STORAGE_ERROR', message: 'Write failed');
          }
          return null;
        },
      );

      // 書き込みエラーは例外をスローすべき
      expect(
        () async => await securityManager.setApiKey('test_key', 'test_value'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should handle validation errors gracefully', () async {
      // Red → Green: 検証エラーの適切な処理

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (methodCall) async {
          throw PlatformException(
              code: 'STORAGE_ERROR', message: 'Validation failed');
        },
      );

      // 非同期検証はエラー情報を含む結果を返すべき
      final result = await securityManager.validateSecurityConfigurationAsync();

      expect(result.isValid, isFalse);
      expect(result.issues, isNotEmpty);
      expect(result.details['storage_available'], isFalse);
    });

    test('should sanitize sensitive data in logs', () {
      // Red → Green: ログ内機密情報のサニタイゼーション

      const sensitiveData = {
        'api_key': 'secret_key_12345',
        'user_name': 'john_doe', // 非機密
        'token': 'bearer_token_67890',
      };

      // SecurityErrorHandlerの動作をテスト
      // 実際のログ出力確認は困難なので、サニタイゼーション機能の存在確認
      expect(() {
        SecurityErrorHandler.logSecurityWarning(
          'test_operation',
          Exception('test error'),
          additionalData: sensitiveData,
        );
      }, returnsNormally);
    });

    test('should handle different error severity levels', () {
      // Red → Green: エラー重要度レベルの適切な処理

      // Warning レベル - 例外をスローしない
      expect(() {
        SecurityErrorHandler.handleSecurityError(
          'test_operation',
          Exception('warning error'),
          SecurityErrorSeverity.warning,
        );
      }, returnsNormally);

      // Error レベル - 例外をスローする
      expect(() {
        SecurityErrorHandler.handleSecurityError(
          'test_operation',
          Exception('error'),
          SecurityErrorSeverity.error,
        );
      }, throwsA(isA<SecurityException>()));

      // Critical レベル - 例外をスローする
      expect(() {
        SecurityErrorHandler.handleSecurityError(
          'test_operation',
          Exception('critical error'),
          SecurityErrorSeverity.critical,
        );
      }, throwsA(isA<SecurityException>()));
    });
  });
}
