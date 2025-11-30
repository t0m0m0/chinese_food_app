import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/constants/log_constants.dart';
import 'package:chinese_food_app/core/di/di_error_handler.dart';
import 'package:chinese_food_app/core/di/base_service_registrator.dart';
import 'package:chinese_food_app/core/di/service_container.dart';

void main() {
  group('DI System Improvements Tests', () {
    group('LogConstants', () {
      test('should define all required log levels', () {
        expect(LogConstants.info, 800);
        expect(LogConstants.warning, 900);
        expect(LogConstants.error, 1000);
        expect(LogConstants.critical, 1200);
      });

      test('should provide log level name mapping', () {
        expect(LogConstants.getLevelName(LogConstants.info), 'INFO');
        expect(LogConstants.getLevelName(LogConstants.warning), 'WARNING');
        expect(LogConstants.getLevelName(LogConstants.error), 'ERROR');
        expect(LogConstants.getLevelName(LogConstants.critical), 'CRITICAL');
        expect(LogConstants.getLevelName(999), 'UNKNOWN');
      });

      test('should validate log levels correctly', () {
        expect(LogConstants.isValidLevel(LogConstants.info), isTrue);
        expect(LogConstants.isValidLevel(LogConstants.warning), isTrue);
        expect(LogConstants.isValidLevel(LogConstants.error), isTrue);
        expect(LogConstants.isValidLevel(LogConstants.critical), isTrue);
        expect(LogConstants.isValidLevel(999), isFalse);
      });
    });

    group('DIErrorHandler', () {
      test('should format user-friendly error messages', () {
        final apiError = Exception('API connection failed');
        final message =
            DIErrorHandler.formatUserFriendlyError('API設定', apiError);
        expect(message, contains('API接続の設定に問題があります'));

        final dbError = Exception('Database connection error');
        final dbMessage =
            DIErrorHandler.formatUserFriendlyError('DB接続', dbError);
        expect(dbMessage, contains('データベース接続に問題があります'));

        final networkError = Exception('Network timeout');
        final networkMessage =
            DIErrorHandler.formatUserFriendlyError('通信', networkError);
        expect(networkMessage, contains('ネットワーク接続に問題があります'));

        final genericError = Exception('Unknown error');
        final genericMessage =
            DIErrorHandler.formatUserFriendlyError('処理', genericError);
        expect(genericMessage, contains('予期しないエラーが発生しました'));
      });

      test('should validate environment configuration', () {
        expect(DIErrorHandler.validateEnvironmentConfiguration('production'),
            isTrue);
        expect(DIErrorHandler.validateEnvironmentConfiguration('development'),
            isTrue);
        expect(DIErrorHandler.validateEnvironmentConfiguration('test'), isTrue);
        expect(DIErrorHandler.validateEnvironmentConfiguration('invalid'),
            isFalse);
      });
    });

    group('BaseServiceRegistrator Enhanced Features', () {
      late ServiceContainer container;

      setUp(() {
        container = ServiceContainer();
      });

      tearDown(() {
        container.dispose();
      });

      // HotpepperApiDatasource関連のテストは削除
      // プロキシサーバー経由でのみAPI呼び出しを行うため不要

      test('should create database connections without errors', () {
        // Database connectionの作成がエラーなく動作することを確認
        expect(() => BaseServiceRegistrator.registerCommonServices(container),
            returnsNormally);
      });
    });

    group('Error Handling Integration', () {
      test('should handle API configuration errors gracefully', () {
        expect(() {
          DIErrorHandler.handleApiConfigurationError(
            'test',
            'APIキー未設定',
            null,
          );
        }, returnsNormally);

        expect(() {
          DIErrorHandler.handleApiConfigurationError(
            'test',
            'エラー発生',
            Exception('Configuration error'),
          );
        }, returnsNormally);
      });

      test('should handle database errors gracefully', () {
        expect(() {
          DIErrorHandler.handleDatabaseError(
            'Test',
            'データベース接続',
            Exception('Connection failed'),
            recoveryHint: 'アプリを再起動してください',
          );
        }, returnsNormally);
      });

      test('should log successful operations', () {
        expect(() {
          DIErrorHandler.logSuccessfulOperation(
            'テスト操作',
            '正常に完了しました',
          );
        }, returnsNormally);

        expect(() {
          DIErrorHandler.logSuccessfulOperation(
            'テスト操作',
            '詳細ログ付きで完了しました',
            isVerbose: true,
          );
        }, returnsNormally);
      });
    });
  });
}
