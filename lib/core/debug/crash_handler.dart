import 'package:flutter/foundation.dart';

/// 最小限のエラーハンドリングユーティリティ
class CrashHandler {
  static bool _initialized = false;

  /// 基本的なエラーハンドラーを初期化
  static void initialize() {
    if (_initialized) return;

    // Flutter Frameworkエラーの基本ハンドリング
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        debugPrint('Flutter Error: ${details.exception}');
        FlutterError.presentError(details);
      }
    };

    // プラットフォームエラーの基本ハンドリング
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Platform Error: $error');
      }
      return true;
    };

    _initialized = true;
  }

  /// デバッグ用ログ出力（最小限）
  static void logEvent(String event, {Map<String, dynamic>? details}) {
    if (kDebugMode) {
      debugPrint('Event: $event');
      if (details != null && details.isNotEmpty) {
        debugPrint('Details: $details');
      }
    }
  }
}
