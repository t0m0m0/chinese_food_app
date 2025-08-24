import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_detector.dart';
import 'logging_config.dart';

/// 環境初期化の責務を担当するクラス
class EnvironmentInitializer {
  /// .envファイルがassetsに存在するかチェック
  static Future<bool> _envFileExists(String fileName) async {
    try {
      await rootBundle.loadString(fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// テスト環境の初期化
  static Future<void> initializeTestEnvironment() async {
    LoggingConfig.debugLog('テスト環境での初期化を開始');

    // テスト中で既にdotenvが設定されている場合は、既存の設定を保持
    final hasExistingTestConfig =
        dotenv.env.isNotEmpty && dotenv.env.containsKey('FLUTTER_ENV');

    if (!hasExistingTestConfig) {
      // .env.testファイルの存在確認
      if (await _envFileExists('.env.test')) {
        LoggingConfig.debugLog('.env.testファイルの読み込みを開始');
        await dotenv.load(fileName: '.env.test');
        LoggingConfig.debugLog('.env.testファイルの読み込み完了');
      } else {
        LoggingConfig.warningLog('.env.testファイルが存在しないため、テスト用設定で初期化');
        await _loadTestDefaults();
      }

      // テスト環境では、既存の FLUTTER_ENV 設定を尊重する
      // dotenv.testLoad() で明示的に設定されている場合はそれを優先
      if (dotenv.env['FLUTTER_ENV']?.isEmpty ?? true) {
        dotenv.env['FLUTTER_ENV'] = 'test';
      }
    } else {
      LoggingConfig.debugLog('テスト中で既存の設定を保持: ${dotenv.env['FLUTTER_ENV']}');
    }
  }

  /// 本番・開発環境の初期化
  static Future<void> initializeProductionOrDevelopmentEnvironment() async {
    LoggingConfig.debugLog('.envファイルの存在確認中...');

    if (await _envFileExists('.env')) {
      LoggingConfig.debugLog('.envファイルが見つかりました。読み込み開始');
      await dotenv.load(fileName: '.env');
      LoggingConfig.debugLog('.envファイルの読み込み完了');

      _logEnvironmentVariables();
    } else {
      LoggingConfig.warningLog('.envファイルが存在しません。環境変数から直接取得します');
      await _loadEnvironmentDefaults();
      LoggingConfig.debugLog('環境変数からの設定完了');
    }
  }

  /// エラー時のフォールバック初期化
  static Future<void> initializeFallback() async {
    if (EnvironmentDetector.isTestEnvironment()) {
      await _initializeTestFallback();
    } else {
      await _initializeDevelopmentFallback();
    }
  }

  /// テスト用デフォルト設定をロード
  static Future<void> _loadTestDefaults() async {
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=testdummyhotpepperkey123456789

''');
  }

  /// 環境変数からのデフォルト設定をロード
  static Future<void> _loadEnvironmentDefaults() async {
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=${const String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development')}
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
  }

  /// 環境変数のログ出力
  static void _logEnvironmentVariables() {
    LoggingConfig.debugLog('読み込まれた環境変数:');
    LoggingConfig.debugLog('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
    LoggingConfig.debugLog(
        '  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']?.isNotEmpty == true ? '設定済み(${dotenv.env['HOTPEPPER_API_KEY']?.length}文字)' : '未設定'}');
  }

  /// テスト環境用フォールバック初期化
  static Future<void> _initializeTestFallback() async {
    try {
      await _loadTestDefaults();
      LoggingConfig.debugLog('テスト環境フォールバック初期化完了');
    } catch (fallbackError) {
      LoggingConfig.errorLog('フォールバック初期化も失敗: $fallbackError');
      dotenv.env['FLUTTER_ENV'] = 'test';
      dotenv.env['HOTPEPPER_API_KEY'] = 'testdummyhotpepperkey123456789';
    }
  }

  /// 開発環境用フォールバック初期化
  static Future<void> _initializeDevelopmentFallback() async {
    LoggingConfig.debugLog('開発環境フォールバックで初期化します');
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=development
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
  }
}
