import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// アプリクラッシュの詳細なログ記録と分析を行うハンドラー
class CrashHandler {
  static bool _initialized = false;
  static final List<String> _crashLogs = [];
  static const int _maxLogEntries = 100;

  /// クラッシュハンドラーを初期化
  static void initialize() {
    if (_initialized) return;

    // Flutter Frameworkエラー
    FlutterError.onError = (FlutterErrorDetails details) {
      final crashInfo = _formatFlutterError(details);
      _logCrash('FLUTTER_ERROR', crashInfo);

      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // プラットフォームエラー（iOS/Android native crashes）
    PlatformDispatcher.instance.onError = (error, stack) {
      final crashInfo = _formatPlatformError(error, stack);
      _logCrash('PLATFORM_ERROR', crashInfo);
      return true;
    };

    _initialized = true;
    _logCrash('SYSTEM', 'CrashHandler initialized');
  }

  /// Google Maps関連の詳細ログ記録
  static void logGoogleMapsEvent(
    String event, {
    Map<String, dynamic>? details,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = StringBuffer();

    logEntry.writeln('=== GOOGLE MAPS EVENT ===');
    logEntry.writeln('Time: $timestamp');
    logEntry.writeln('Event: $event');

    if (details != null) {
      logEntry.writeln('Details:');
      details.forEach((key, value) {
        logEntry.writeln('  $key: $value');
      });
    }

    if (stackTrace != null) {
      logEntry.writeln('Stack Trace:');
      logEntry.writeln(stackTrace.toString());
    }

    logEntry.writeln('========================');

    _addToLog(logEntry.toString());

    if (kDebugMode) {
      debugPrint('🗺️ GoogleMaps: $event');
      if (details != null) {
        debugPrint('Details: $details');
      }
    }
  }

  /// システム情報と一緒にクラッシュをログ
  static void _logCrash(String type, String crashInfo) {
    final timestamp = DateTime.now().toIso8601String();
    final systemInfo = _getSystemInfo();

    final logEntry = StringBuffer();
    logEntry.writeln('=== CRASH DETECTED ===');
    logEntry.writeln('Time: $timestamp');
    logEntry.writeln('Type: $type');
    logEntry.writeln('System Info:');
    logEntry.writeln(systemInfo);
    logEntry.writeln('Crash Details:');
    logEntry.writeln(crashInfo);
    logEntry.writeln('==================');

    _addToLog(logEntry.toString());

    if (kDebugMode) {
      debugPrint('💥 CRASH: $type');
      debugPrint(crashInfo);
    }
  }

  /// Flutter Frameworkエラーをフォーマット
  static String _formatFlutterError(FlutterErrorDetails details) {
    final buffer = StringBuffer();
    buffer.writeln('Exception: ${details.exception}');
    buffer.writeln('Library: ${details.library ?? 'Unknown'}');
    buffer.writeln('Context: ${details.context?.toString() ?? 'No context'}');

    if (details.stack != null) {
      buffer.writeln('Stack trace:');
      buffer.writeln(details.stack.toString());
    }

    return buffer.toString();
  }

  /// プラットフォームエラーをフォーマット
  static String _formatPlatformError(Object error, StackTrace stack) {
    final buffer = StringBuffer();
    buffer.writeln('Error: $error');
    buffer.writeln('Type: ${error.runtimeType}');
    buffer.writeln('Stack trace:');
    buffer.writeln(stack.toString());

    return buffer.toString();
  }

  /// システム情報を取得
  static String _getSystemInfo() {
    final buffer = StringBuffer();

    try {
      buffer.writeln('Platform: ${Platform.operatingSystem}');
      buffer.writeln('Version: ${Platform.operatingSystemVersion}');
      buffer.writeln('Dart Version: ${Platform.version}');
      buffer.writeln('Number of processors: ${Platform.numberOfProcessors}');
      buffer.writeln('Path separator: ${Platform.pathSeparator}');

      if (Platform.isAndroid || Platform.isIOS) {
        buffer.writeln('Mobile platform detected');
      }

      // メモリ情報（可能な場合）
      buffer.writeln('Debug mode: $kDebugMode');
      buffer.writeln('Profile mode: $kProfileMode');
      buffer.writeln('Release mode: $kReleaseMode');
    } catch (e) {
      buffer.writeln('Error getting system info: $e');
    }

    return buffer.toString();
  }

  /// ログエントリを追加（リングバッファー式）
  static void _addToLog(String entry) {
    _crashLogs.add(entry);

    // 最大ログ数を超えた場合、古いものから削除
    while (_crashLogs.length > _maxLogEntries) {
      _crashLogs.removeAt(0);
    }
  }

  /// すべてのクラッシュログを取得
  static List<String> getCrashLogs() {
    return List.unmodifiable(_crashLogs);
  }

  /// 最新のクラッシュログを取得
  static String getLatestCrashLog() {
    if (_crashLogs.isEmpty) {
      return 'No crash logs available';
    }
    return _crashLogs.last;
  }

  /// ログをクリア
  static void clearLogs() {
    _crashLogs.clear();
    _logCrash('SYSTEM', 'Crash logs cleared');
  }

  /// ログをファイルに出力（デバッグ用）
  static Future<String?> exportLogsToFile() async {
    if (!kDebugMode) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'crash_logs_$timestamp.txt';

      final buffer = StringBuffer();
      buffer.writeln('Chinese Food App - Crash Logs');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total entries: ${_crashLogs.length}');
      buffer.writeln('${'=' * 50}');

      for (final log in _crashLogs) {
        buffer.writeln(log);
        buffer.writeln();
      }

      if (kDebugMode) {
        debugPrint('📄 Crash logs exported to: $filename');
        debugPrint('Total log entries: ${_crashLogs.length}');
      }

      return buffer.toString();
    } catch (e) {
      _logCrash('EXPORT_ERROR', 'Failed to export logs: $e');
      return null;
    }
  }

  /// Google Maps関連のメトリクス収集
  static void collectGoogleMapsMetrics() {
    logGoogleMapsEvent('METRICS_COLLECTION', details: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'total_crashes': _crashLogs.where((log) => log.contains('GOOGLE')).length,
      'platform': Platform.operatingSystem,
      'debug_mode': kDebugMode,
    });
  }
}
