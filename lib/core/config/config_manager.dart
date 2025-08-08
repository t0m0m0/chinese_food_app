import 'dart:async';
import 'dart:developer' as developer;

import 'config_exception.dart';
import 'config_validator.dart';
import 'environment_config.dart';
import 'managers/api_config_manager.dart';
import 'managers/database_config_manager.dart';
import 'managers/location_config_manager.dart';
import 'managers/search_config_manager.dart';
import 'managers/ui_config_manager.dart';

/// 設定管理クラス
///
/// アプリケーション全体の設定を統一的に管理します。
/// 環境別設定、APIキー、その他の設定値への統一インターフェースを提供します。
class ConfigManager {
  static bool _isInitialized = false;
  static late Map<String, dynamic> _runtimeConfig;

  /// 設定変更の通知用StreamController
  static final StreamController<Map<String, dynamic>> _configChangeController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 設定変更の通知Stream
  static Stream<Map<String, dynamic>> get configChanges =>
      _configChangeController.stream;

  /// 設定管理を初期化
  ///
  /// アプリケーション起動時に一度だけ呼び出される必要があります。
  /// 設定の検証を行い、問題がある場合は例外をスローします。
  static Future<void> initialize({
    bool throwOnValidationError = true,
    bool enableDebugLogging = false,
  }) async {
    try {
      if (enableDebugLogging) {
        developer.log('設定管理の初期化を開始します', name: 'ConfigManager');
      }

      // 設定検証を実行
      final validationErrors = ConfigValidator.validateConfiguration();

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.join('\n');

        if (enableDebugLogging) {
          developer.log(
            '設定検証エラー: $errorMessage',
            name: 'ConfigManager',
          );
        }

        if (throwOnValidationError) {
          throw ConfigurationException(errorMessage);
        }
      }

      // ランタイム設定を構築
      _runtimeConfig = _buildRuntimeConfig();

      _isInitialized = true;

      if (enableDebugLogging) {
        developer.log(
          '設定管理の初期化が完了しました: ${EnvironmentConfig.debugInfo}',
          name: 'ConfigManager',
        );
      }
    } catch (e) {
      developer.log(
        '設定管理の初期化に失敗しました: $e',
        name: 'ConfigManager',
        error: e,
      );
      rethrow;
    }
  }

  /// 初期化済みかどうかを確認
  static bool get isInitialized => _isInitialized;

  /// 初期化を強制する（テスト用）
  static void forceInitialize() {
    _isInitialized = false;
  }

  /// 設定の非同期プリロード（重い処理を事前に実行）
  ///
  /// アプリ起動時間を短縮するため、設定検証処理を事前に実行します。
  /// 初期化前に呼び出すことで、initialize()の処理時間を短縮できます。
  static Future<void> preloadConfiguration({
    bool enableDebugLogging = false,
  }) async {
    try {
      if (enableDebugLogging) {
        developer.log('設定のプリロードを開始します', name: 'ConfigManager');
      }

      // 設定検証を非同期で実行
      await Future.microtask(() {
        final validationErrors = ConfigValidator.validateConfiguration();

        if (enableDebugLogging) {
          if (validationErrors.isEmpty) {
            developer.log('設定の事前検証が完了しました', name: 'ConfigManager');
          } else {
            developer.log(
              '設定の事前検証で問題を検出しました: ${validationErrors.length}件',
              name: 'ConfigManager',
            );
          }
        }
      });

      if (enableDebugLogging) {
        developer.log('設定のプリロードが完了しました', name: 'ConfigManager');
      }
    } catch (e) {
      if (enableDebugLogging) {
        developer.log(
          '設定のプリロードに失敗しました: $e',
          name: 'ConfigManager',
          error: e,
        );
      }
      // プリロード失敗は致命的ではないため、例外を再スローしない
    }
  }

  /// 初期化チェック
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'ConfigManager が初期化されていません。main() で '
        'ConfigManager.initialize() を呼び出してください。',
      );
    }
  }

  /// ランタイム設定を構築
  static Map<String, dynamic> _buildRuntimeConfig() {
    return {
      'environment': EnvironmentConfig.current.name,
      'hotpepperApiKey': EnvironmentConfig.effectiveHotpepperApiKey,
      'googleMapsApiKey': EnvironmentConfig.effectiveGoogleMapsApiKey,
      'hotpepperApiUrl': EnvironmentConfig.hotpepperApiUrl,
      'isDevelopment': EnvironmentConfig.isDevelopment,
      'isStaging': EnvironmentConfig.isStaging,
      'isProduction': EnvironmentConfig.isProduction,
      'isValid': ConfigValidator.isConfigurationValid,
      'hasCriticalErrors': ConfigValidator.hasCriticalErrors,
    };
  }

  // === Public API ===

  /// 現在の環境を取得
  static Environment get environment {
    _ensureInitialized();
    return EnvironmentConfig.current;
  }

  /// HotPepper API キーを取得
  static String get hotpepperApiKey {
    _ensureInitialized();
    return _runtimeConfig['hotpepperApiKey'] as String;
  }

  /// Google Maps API キーを取得
  static String get googleMapsApiKey {
    _ensureInitialized();
    return _runtimeConfig['googleMapsApiKey'] as String;
  }

  /// HotPepper API ベースURLを取得
  static String get hotpepperApiUrl {
    _ensureInitialized();
    return _runtimeConfig['hotpepperApiUrl'] as String;
  }

  /// 開発環境かどうかを判定
  static bool get isDevelopment {
    _ensureInitialized();
    return _runtimeConfig['isDevelopment'] as bool;
  }

  /// ステージング環境かどうかを判定
  static bool get isStaging {
    _ensureInitialized();
    return _runtimeConfig['isStaging'] as bool;
  }

  /// 本番環境かどうかを判定
  static bool get isProduction {
    _ensureInitialized();
    return _runtimeConfig['isProduction'] as bool;
  }

  /// 設定が有効かどうかを判定
  static bool get isConfigurationValid {
    _ensureInitialized();
    return _runtimeConfig['isValid'] as bool;
  }

  /// 重要なエラーがあるかどうかを判定
  static bool get hasCriticalErrors {
    _ensureInitialized();
    return _runtimeConfig['hasCriticalErrors'] as bool;
  }

  /// 全設定検証でCriticalエラーがあるかを判定
  static bool get hasAnyCriticalErrors {
    _ensureInitialized();
    return ConfigValidator.hasAnyCriticalErrors;
  }

  /// APIキーが有効かどうかを判定
  static bool get hasValidApiKeys {
    _ensureInitialized();
    return hotpepperApiKey.isNotEmpty && googleMapsApiKey.isNotEmpty;
  }

  /// 設定の検証を再実行
  static List<String> validateConfiguration() {
    _ensureInitialized();
    return ConfigValidator.validateConfiguration();
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    _ensureInitialized();
    return {
      ..._runtimeConfig,
      'validationErrors': ConfigValidator.validateConfiguration(),
      'configurationDetails': ConfigValidator.configurationDetails,
    };
  }

  /// 設定情報を文字列で取得（デバッグ表示用）
  static String get debugString {
    if (!_isInitialized) {
      return 'ConfigManager: 未初期化';
    }

    final info = debugInfo;
    return '''
ConfigManager 設定情報:
- 環境: ${info['environment']}
- HotPepper APIキー: ${info['hotpepperApiKey'].toString().isNotEmpty ? '設定済み' : '未設定'}
- Google Maps APIキー: ${info['googleMapsApiKey'].toString().isNotEmpty ? '設定済み' : '未設定'}
- 設定有効: ${info['isValid']}
- 重要エラー: ${info['hasCriticalErrors']}
''';
  }

  /// 特定の設定値を取得（拡張可能なAPI）
  static T getValue<T>(String key, T defaultValue) {
    _ensureInitialized();
    return _runtimeConfig[key] as T? ?? defaultValue;
  }

  /// 設定値を動的に設定（テスト用・リアクティブ対応）
  static void setValue(String key, dynamic value) {
    _ensureInitialized();
    final oldValue = _runtimeConfig[key];
    _runtimeConfig[key] = value;

    // 値が変更された場合、通知を送信
    if (oldValue != value) {
      _configChangeController.add({
        'key': key,
        'oldValue': oldValue,
        'newValue': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 設定変更の通知を停止（テスト用）
  static void dispose() {
    _configChangeController.close();
  }

  // === 分野別設定アクセス ===

  /// API設定を取得
  static Map<String, dynamic> get apiConfig {
    return ApiConfigManager.debugInfo;
  }

  /// 位置情報設定を取得
  static Map<String, dynamic> get locationConfig {
    return LocationConfigManager.debugInfo;
  }

  /// 検索設定を取得
  static Map<String, dynamic> get searchConfig {
    return SearchConfigManager.debugInfo;
  }

  /// UI設定を取得
  static Map<String, dynamic> get uiConfig {
    return UiConfigManager.debugInfo;
  }

  /// データベース設定を取得
  static Map<String, dynamic> get databaseConfig {
    return DatabaseConfigManager.debugInfo;
  }

  /// 全設定情報を統合して取得
  static Map<String, dynamic> get allConfigs {
    _ensureInitialized();
    return {
      'runtime': _runtimeConfig,
      'api': apiConfig,
      'location': locationConfig,
      'search': searchConfig,
      'ui': uiConfig,
      'database': databaseConfig,
    };
  }

  /// 設定の整合性チェック
  static Map<String, List<String>> validateAllConfigs() {
    _ensureInitialized();
    return {
      'runtime': validateConfiguration(),
      'api': ApiConfigManager.validate(),
      'location': LocationConfigManager.validate(),
      'search': SearchConfigManager.validate(),
      'ui': UiConfigManager.validate(),
      'database': DatabaseConfigManager.validate(),
    };
  }
}
