import '../config/operations_config.dart';
import '../types/result.dart';
import '../exceptions/base_exception.dart';

/// クラッシュレポート・エラー監視サービス
/// Issue #144: 運用・サポート体制整備のクラッシュ監視機能
class CrashMonitoringService {
  // メモリ上でのエラー記録（本番環境ではFirebase Crashlyticsを使用）
  final List<ErrorRecord> _errorRecords = [];
  int _totalSessions = 0;
  int _crashedSessions = 0;

  /// Firebase Crashlyticsの初期化
  Future<Result<void>> initializeCrashlytics() async {
    try {
      // テスト環境では実際の初期化は行わない
      // 本番環境では以下のような初期化を行う:
      // await Firebase.initializeApp();
      // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      return Failure(BaseException('テスト環境ではCrashlyticsを初期化できません'));
    } catch (e) {
      return Failure(BaseException('Crashlyticsの初期化に失敗しました: $e'));
    }
  }

  /// エラーを記録する
  Future<Result<void>> recordError({
    required Object error,
    required StackTrace? stackTrace,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        return Failure(BaseException('エラーの理由を入力してください。'));
      }

      // エラー記録をメモリに保存（本番環境ではCrashlyticsに送信）
      final record = ErrorRecord(
        error: error,
        stackTrace: stackTrace,
        reason: reason,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        severity: _determineSeverity(error),
      );

      _errorRecords.add(record);

      // テスト環境では常に失敗を返す（実際の送信はできないため）
      return Failure(BaseException('テスト環境ではエラー記録を送信できません'));
    } catch (e) {
      return Failure(BaseException('エラー記録の送信に失敗しました: $e'));
    }
  }

  /// カスタムエラーを記録する
  Future<Result<void>> recordCustomError({
    required String title,
    required String message,
    required CrashSeverity severity,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (title.trim().isEmpty) {
        return Failure(BaseException('エラータイトルを入力してください。'));
      }

      if (message.trim().isEmpty) {
        return Failure(BaseException('エラーメッセージを入力してください。'));
      }

      // カスタムエラー記録
      final record = ErrorRecord(
        error: CustomError(title, message),
        stackTrace: null,
        reason: title,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        severity: severity,
      );

      _errorRecords.add(record);

      return Failure(BaseException('テスト環境ではカスタムエラーを送信できません'));
    } catch (e) {
      return Failure(BaseException('カスタムエラー記録の送信に失敗しました: $e'));
    }
  }

  /// ログメッセージを記録する
  Future<Result<void>> logMessage(
    String message, {
    required LogLevel level,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (message.trim().isEmpty) {
        return Failure(BaseException('ログメッセージを入力してください。'));
      }

      // ログ記録（本番環境ではCrashlyticsに送信）
      // 将来的にはlogRecordをCrashlyticsに送信
      // final logRecord = LogRecord(
      //   message: message,
      //   level: level,
      //   metadata: metadata ?? {},
      //   timestamp: DateTime.now(),
      // );

      // テスト環境では常に失敗を返す
      return Failure(BaseException('テスト環境ではログメッセージを送信できません'));
    } catch (e) {
      return Failure(BaseException('ログメッセージの記録に失敗しました: $e'));
    }
  }

  /// ユーザー識別子を設定する
  Future<Result<void>> setUserIdentifier(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        return Failure(BaseException('ユーザーIDを入力してください。'));
      }

      // 本番環境では FirebaseCrashlytics.instance.setUserIdentifier(userId);
      return Failure(BaseException('テスト環境ではユーザー識別子を設定できません'));
    } catch (e) {
      return Failure(BaseException('ユーザー識別子の設定に失敗しました: $e'));
    }
  }

  /// 現在のクラッシュ率を取得する
  CrashRateInfo getCrashRate() {
    // テスト環境では模擬データを返す
    _totalSessions = _totalSessions > 0 ? _totalSessions : 100;
    _crashedSessions = _errorRecords
        .where((record) => record.severity == CrashSeverity.critical)
        .length;

    final rate = _totalSessions > 0 ? _crashedSessions / _totalSessions : 0.0;

    return CrashRateInfo(
      rate: rate,
      totalSessions: _totalSessions,
      crashedSessions: _crashedSessions,
      threshold: OperationsConfig.crashRateThreshold,
      lastUpdated: DateTime.now(),
    );
  }

  /// クラッシュ率が閾値を超えているかチェック
  bool isThresholdExceeded() {
    final crashRate = getCrashRate();
    return crashRate.rate > OperationsConfig.crashRateThreshold;
  }

  /// エラーレポート概要を取得する
  ErrorReportSummary getErrorReport() {
    final criticalErrors = _errorRecords
        .where((record) => record.severity == CrashSeverity.critical)
        .length;

    final highErrors = _errorRecords
        .where((record) => record.severity == CrashSeverity.high)
        .length;

    final mediumErrors = _errorRecords
        .where((record) => record.severity == CrashSeverity.medium)
        .length;

    final lowErrors = _errorRecords
        .where((record) => record.severity == CrashSeverity.low)
        .length;

    return ErrorReportSummary(
      totalErrors: _errorRecords.length,
      criticalErrors: criticalErrors,
      highErrors: highErrors,
      warningErrors: mediumErrors + lowErrors,
      recentErrors: _errorRecords
          .where((record) =>
              DateTime.now().difference(record.timestamp).inHours < 24)
          .toList(),
      lastUpdated: DateTime.now(),
    );
  }

  // プライベートメソッド

  CrashSeverity _determineSeverity(Object error) {
    if (error is Error) {
      return CrashSeverity.critical;
    } else if (error.toString().toLowerCase().contains('network')) {
      return CrashSeverity.medium;
    } else if (error.toString().toLowerCase().contains('warning')) {
      return CrashSeverity.low;
    } else {
      return CrashSeverity.high;
    }
  }
}

// データクラス定義

enum CrashSeverity {
  low,
  medium,
  high,
  critical,
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class ErrorRecord {
  final Object error;
  final StackTrace? stackTrace;
  final String reason;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final CrashSeverity severity;

  const ErrorRecord({
    required this.error,
    required this.stackTrace,
    required this.reason,
    required this.metadata,
    required this.timestamp,
    required this.severity,
  });
}

class LogRecord {
  final String message;
  final LogLevel level;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const LogRecord({
    required this.message,
    required this.level,
    required this.metadata,
    required this.timestamp,
  });
}

class CustomError {
  final String title;
  final String message;

  const CustomError(this.title, this.message);

  @override
  String toString() => 'CustomError: $title - $message';
}

class CrashRateInfo {
  final double rate;
  final int totalSessions;
  final int crashedSessions;
  final double threshold;
  final DateTime lastUpdated;

  const CrashRateInfo({
    required this.rate,
    required this.totalSessions,
    required this.crashedSessions,
    required this.threshold,
    required this.lastUpdated,
  });
}

class ErrorReportSummary {
  final int totalErrors;
  final int criticalErrors;
  final int highErrors;
  final int warningErrors;
  final List<ErrorRecord> recentErrors;
  final DateTime lastUpdated;

  const ErrorReportSummary({
    required this.totalErrors,
    required this.criticalErrors,
    required this.highErrors,
    required this.warningErrors,
    required this.recentErrors,
    required this.lastUpdated,
  });
}
