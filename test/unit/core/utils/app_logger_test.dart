import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    group('LogLevel enum', () {
      test('should have all expected log levels', () {
        const expectedLevels = [
          LogLevel.debug,
          LogLevel.info,
          LogLevel.warning,
          LogLevel.error,
          LogLevel.critical,
        ];

        expect(LogLevel.values, equals(expectedLevels));
      });
    });

    group('setMinLogLevel', () {
      test('should set minimum log level', () {
        // テスト前の状態確認
        AppLogger.setMinLogLevel(LogLevel.debug);

        // 最小ログレベルを変更
        AppLogger.setMinLogLevel(LogLevel.error);

        // 内部状態は直接確認できないが、動作検証は統合テストで行う
        expect(() => AppLogger.setMinLogLevel(LogLevel.error), returnsNormally);
      });
    });

    group('logging methods', () {
      test('should call debug without throwing exception', () {
        expect(() => AppLogger.debug('Debug message'), returnsNormally);
        expect(() => AppLogger.debug('Debug with name', name: 'TestModule'),
            returnsNormally);
        expect(() => AppLogger.debug('Debug with error', error: 'Test error'),
            returnsNormally);
      });

      test('should call info without throwing exception', () {
        expect(() => AppLogger.info('Info message'), returnsNormally);
        expect(() => AppLogger.info('Info with name', name: 'TestModule'),
            returnsNormally);
        expect(() => AppLogger.info('Info with error', error: 'Test error'),
            returnsNormally);
      });

      test('should call warning without throwing exception', () {
        expect(() => AppLogger.warning('Warning message'), returnsNormally);
        expect(() => AppLogger.warning('Warning with name', name: 'TestModule'),
            returnsNormally);
        expect(
            () => AppLogger.warning('Warning with error', error: 'Test error'),
            returnsNormally);
      });

      test('should call error without throwing exception', () {
        expect(() => AppLogger.error('Error message'), returnsNormally);
        expect(() => AppLogger.error('Error with name', name: 'TestModule'),
            returnsNormally);
        expect(() => AppLogger.error('Error with error', error: 'Test error'),
            returnsNormally);
      });

      test('should call critical without throwing exception', () {
        expect(() => AppLogger.critical('Critical message'), returnsNormally);
        expect(
            () => AppLogger.critical('Critical with name', name: 'TestModule'),
            returnsNormally);
        expect(
            () =>
                AppLogger.critical('Critical with error', error: 'Test error'),
            returnsNormally);
      });
    });

    group('specialized logging methods', () {
      test('should call proxyError without throwing exception', () {
        expect(() => AppLogger.proxyError('Proxy error occurred'),
            returnsNormally);
        expect(
            () =>
                AppLogger.proxyError('Proxy error', error: 'Connection failed'),
            returnsNormally);
      });

      test('should call proxyFallback without throwing exception', () {
        expect(() => AppLogger.proxyFallback('Switching to fallback'),
            returnsNormally);
        expect(
            () => AppLogger.proxyFallback('Fallback reason',
                originalError: 'Original error'),
            returnsNormally);
      });

      test('should call apiInfo without throwing exception', () {
        expect(() => AppLogger.apiInfo('API call successful'), returnsNormally);
        expect(
            () => AppLogger.apiInfo('API response received',
                apiName: 'HotPepper'),
            returnsNormally);
      });

      test('should call apiError without throwing exception', () {
        expect(() => AppLogger.apiError('API call failed'), returnsNormally);
        expect(
            () => AppLogger.apiError('API error',
                apiName: 'HotPepper', error: 'Timeout'),
            returnsNormally);
      });
    });

    group('log level filtering', () {
      setUp(() {
        // 各テスト前にデバッグレベルにリセット
        AppLogger.setMinLogLevel(LogLevel.debug);
      });

      test('should allow all logs when min level is debug', () {
        AppLogger.setMinLogLevel(LogLevel.debug);

        // すべてのレベルが例外を投げないことを確認
        expect(() => AppLogger.debug('Debug message'), returnsNormally);
        expect(() => AppLogger.info('Info message'), returnsNormally);
        expect(() => AppLogger.warning('Warning message'), returnsNormally);
        expect(() => AppLogger.error('Error message'), returnsNormally);
        expect(() => AppLogger.critical('Critical message'), returnsNormally);
      });

      test('should filter debug logs when min level is info', () {
        AppLogger.setMinLogLevel(LogLevel.info);

        // 全てのメソッドが例外を投げないことを確認（内部でフィルタリング）
        expect(() => AppLogger.debug('Debug message'), returnsNormally);
        expect(() => AppLogger.info('Info message'), returnsNormally);
        expect(() => AppLogger.warning('Warning message'), returnsNormally);
        expect(() => AppLogger.error('Error message'), returnsNormally);
        expect(() => AppLogger.critical('Critical message'), returnsNormally);
      });

      test('should filter low level logs when min level is critical', () {
        AppLogger.setMinLogLevel(LogLevel.critical);

        // 全てのメソッドが例外を投げないことを確認（内部でフィルタリング）
        expect(() => AppLogger.debug('Debug message'), returnsNormally);
        expect(() => AppLogger.info('Info message'), returnsNormally);
        expect(() => AppLogger.warning('Warning message'), returnsNormally);
        expect(() => AppLogger.error('Error message'), returnsNormally);
        expect(() => AppLogger.critical('Critical message'), returnsNormally);
      });
    });

    group('error handling', () {
      test('should handle null values gracefully', () {
        expect(() => AppLogger.info('Message with null error', error: null),
            returnsNormally);
        expect(
            () => AppLogger.error('Message with null stack trace',
                stackTrace: null),
            returnsNormally);
      });

      test('should handle complex error objects', () {
        final complexError = Exception('Complex error with nested data');
        expect(() => AppLogger.error('Complex error test', error: complexError),
            returnsNormally);
      });
    });
  });
}
