import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境検出の責務を担当するクラス
class EnvironmentDetector {
  // テスト実行フラグ（テスト時に明示的に設定）
  static bool _isInTestContext = false;

  /// テスト用: テストコンテキストを設定
  static void setTestContext() {
    _isInTestContext = true;
  }

  /// テスト用: テストコンテキストをクリア
  static void clearTestContext() {
    _isInTestContext = false;
  }

  /// 現在の環境文字列を検出
  static String detectEnvironment() {
    String env = 'development';

    try {
      // DotEnvが初期化されている場合は、DotEnvから環境を取得
      if (dotenv.env.isNotEmpty) {
        env = dotenv.env['FLUTTER_ENV'] ?? 'development';
      } else {
        // DotEnvが利用できない場合は、コンパイル時環境変数から取得
        env = const String.fromEnvironment('FLUTTER_ENV',
            defaultValue: 'development');
      }
    } catch (e) {
      // DotEnvが初期化されていない場合は、コンパイル時環境変数から取得
      env = const String.fromEnvironment('FLUTTER_ENV',
          defaultValue: 'development');
    }

    // テスト環境の場合でも、明示的に設定された環境を優先
    // ただし、明示的な環境設定がない場合のみテストをデフォルトにする
    if (isTestEnvironment() && env == 'development') {
      env = 'test';
    }

    return env;
  }

  /// テスト環境かどうかを判定
  static bool isTestEnvironment() {
    // テストコンテキストフラグが設定されている場合
    if (_isInTestContext) {
      return true;
    }

    // Flutter test環境の検出
    if (const bool.fromEnvironment('flutter.test', defaultValue: false) ||
        const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
      return true;
    }

    // kDebugMode でテスト環境の可能性をチェック
    if (kDebugMode) {
      // デバッグモードでスタックトレースからテスト実行を検出
      try {
        final stackTrace = StackTrace.current;
        if (stackTrace.toString().contains('flutter_test') ||
            stackTrace.toString().contains('test_api')) {
          return true;
        }
      } catch (e) {
        // スタックトレース取得に失敗した場合は無視
      }
    }

    // DotEnvからのテスト環境検出
    try {
      if (dotenv.env.isNotEmpty && dotenv.env['FLUTTER_ENV'] == 'test') {
        return true;
      }
    } catch (e) {
      // DotEnv未初期化の場合は無視
    }

    return false;
  }

  /// 開発環境かどうかを判定
  static bool isDevelopmentEnvironment(String env) {
    return env == 'development';
  }

  /// 本番環境かどうかを判定
  static bool isProductionEnvironment(String env) {
    return env == 'production';
  }

  /// ステージング環境かどうかを判定
  static bool isStagingEnvironment(String env) {
    return env == 'staging';
  }

  /// テスト環境かどうかを判定（環境文字列から）
  static bool isTestEnvironmentFromString(String env) {
    return env == 'test';
  }
}
