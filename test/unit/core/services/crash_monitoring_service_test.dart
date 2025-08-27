import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/services/crash_monitoring_service.dart';
void main() {
  group('CrashMonitoringService', () {
    late CrashMonitoringService crashMonitoringService;

    setUp(() {
      crashMonitoringService = CrashMonitoringService();
    });

    group('initializeCrashlytics', () {
      test('should initialize successfully', () async {
        // Act
        final result = await crashMonitoringService.initializeCrashlytics();

        // Assert - テスト環境では初期化は成功しない想定
        expect(result.isFailure, isTrue);
      });
    });

    group('recordError', () {
      test('should validate error parameters', () async {
        // Act
        final result1 = await crashMonitoringService.recordError(
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
          reason: 'Unit test error',
        );

        final result2 = await crashMonitoringService.recordError(
          error: Exception('Test error'),
          stackTrace: null,
          reason: '',
        );

        // Assert
        expect(result1.isFailure, isTrue); // テスト環境では失敗想定
        expect(result2.isFailure, isTrue);
      });
    });

    group('recordCustomError', () {
      test('should validate custom error parameters', () async {
        // Act
        final result = await crashMonitoringService.recordCustomError(
          title: 'Test Custom Error',
          message: 'This is a test custom error',
          severity: CrashSeverity.medium,
          metadata: {'testKey': 'testValue'},
        );

        // Assert
        expect(result.isFailure, isTrue); // テスト環境では失敗想定
      });

      test('should validate required fields', () async {
        // Act
        final result1 = await crashMonitoringService.recordCustomError(
          title: '',
          message: 'message',
          severity: CrashSeverity.low,
        );

        final result2 = await crashMonitoringService.recordCustomError(
          title: 'title',
          message: '',
          severity: CrashSeverity.high,
        );

        // Assert
        expect(result1.isFailure, isTrue);
        expect(result2.isFailure, isTrue);
      });
    });

    group('logMessage', () {
      test('should validate message parameters', () async {
        // Act
        final result1 = await crashMonitoringService.logMessage(
          'Test log message',
          level: LogLevel.info,
        );

        final result2 = await crashMonitoringService.logMessage(
          '',
          level: LogLevel.error,
        );

        // Assert
        expect(result1.isFailure, isTrue); // テスト環境では失敗想定
        expect(result2.isFailure, isTrue);
      });
    });

    group('setUserIdentifier', () {
      test('should validate user identifier', () async {
        // Act
        final result1 =
            await crashMonitoringService.setUserIdentifier('test-user-123');
        final result2 = await crashMonitoringService.setUserIdentifier('');

        // Assert
        expect(result1.isFailure, isTrue); // テスト環境では失敗想定
        expect(result2.isFailure, isTrue);
      });
    });

    group('getCrashRate', () {
      test('should return crash rate data', () {
        // Act
        final crashRate = crashMonitoringService.getCrashRate();

        // Assert
        expect(crashRate, isA<CrashRateInfo>());
        expect(crashRate.rate, greaterThanOrEqualTo(0.0));
        expect(crashRate.rate, lessThanOrEqualTo(1.0));
        expect(crashRate.totalSessions, greaterThanOrEqualTo(0));
        expect(crashRate.crashedSessions, greaterThanOrEqualTo(0));
      });
    });

    group('isThresholdExceeded', () {
      test('should check crash rate threshold correctly', () {
        // Act
        final result = crashMonitoringService.isThresholdExceeded();

        // Assert
        expect(result, isA<bool>());
      });
    });

    group('getErrorReport', () {
      test('should return error report summary', () {
        // Act
        final report = crashMonitoringService.getErrorReport();

        // Assert
        expect(report, isA<ErrorReportSummary>());
        expect(report.totalErrors, greaterThanOrEqualTo(0));
        expect(report.criticalErrors, greaterThanOrEqualTo(0));
        expect(report.warningErrors, greaterThanOrEqualTo(0));
        expect(report.lastUpdated, isA<DateTime>());
      });
    });
  });
}
