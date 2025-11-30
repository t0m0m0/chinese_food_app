import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';
import 'database_config.dart';
import 'environment_config.dart';
import 'location_config.dart';
import 'search_config.dart';
import 'ui_config.dart';

/// 設定検証クラス
class ConfigValidator {
  /// 設定全体の検証を実行し、エラーリストを返す
  static List<String> validateConfiguration() {
    final errors = <String>[];

    // DotEnvの初期化確認を最優先で実行
    try {
      // DotEnvにアクセステストを実行
      final _ = dotenv.env;
    } catch (e) {
      if (e is NotInitializedError) {
        errors.add('DotEnvが初期化されていません。テスト環境では'
            'TestEnvSetup.initializeTestEnvironment()を呼び出してください。');
        return errors;
      }
      // その他のエラーは警告として扱う
      errors.add('DotEnv設定の読み込みエラー: $e');
    }

    // 初期化を確実に行う（同期的処理のみ）
    if (!EnvironmentConfig.isInitialized) {
      errors.add('EnvironmentConfigが初期化されていません。main()で'
          'EnvironmentConfig.initialize()を呼び出してください。');
      return errors;
    }

    // APIキーの存在確認
    _validateApiKeys(errors);

    // APIキーの形式検証
    _validateApiKeyFormats(errors);

    // 環境固有の検証
    _validateEnvironmentSpecificConfig(errors);

    // 分野別設定の検証
    _validateDomainConfigs(errors);

    return errors;
  }

  /// APIキーの存在を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーは不要
  static void _validateApiKeys(List<String> errors) {
    // HotPepper APIキー検証は削除（プロキシ経由でAPI呼び出しを行うため）
  }

  /// APIキーの形式を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーの形式検証は不要
  static void _validateApiKeyFormats(List<String> errors) {
    // HotPepper APIキー形式検証は削除（プロキシ経由でAPI呼び出しを行うため）
    // Google Maps APIキーの形式チェックは削除（WebView実装により不要）
  }

  /// 環境固有の設定を検証
  static void _validateEnvironmentSpecificConfig(List<String> errors) {
    final currentEnv = EnvironmentConfig.current;

    switch (currentEnv) {
      case Environment.production:
        _validateProductionConfig(errors);
        break;
      case Environment.staging:
        _validateStagingConfig(errors);
        break;
      case Environment.development:
        _validateDevelopmentConfig(errors);
        break;
      case Environment.test:
        _validateTestConfig(errors);
        break;
    }
  }

  /// 本番環境の設定を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーは不要
  static void _validateProductionConfig(List<String> errors) {
    // HotPepper APIキー検証は削除（プロキシ経由でAPI呼び出しを行うため）
  }

  /// ステージング環境の設定を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーは不要
  static void _validateStagingConfig(List<String> errors) {
    // HotPepper APIキー検証は削除（プロキシ経由でAPI呼び出しを行うため）
  }

  /// 開発環境の設定を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーは不要
  static void _validateDevelopmentConfig(List<String> errors) {
    // HotPepper APIキー検証は削除（プロキシ経由でAPI呼び出しを行うため）
  }

  /// テスト環境の設定を検証
  /// プロキシサーバー経由でAPI呼び出しを行うため、HotPepper APIキーは不要
  static void _validateTestConfig(List<String> errors) {
    // HotPepper APIキー検証は削除（プロキシ経由でAPI呼び出しを行うため）
  }

  /// 設定が有効かどうかを判定
  static bool get isConfigurationValid {
    return validateConfiguration().isEmpty;
  }

  /// 重要なエラー（本番環境やセキュリティ関連）があるかを判定
  static bool get hasCriticalErrors {
    final errors = validateConfiguration();
    return errors.any((error) =>
        error.contains('production環境') ||
        error.contains('形式が無効') ||
        error.contains('警告: production環境'));
  }

  /// 全設定検証でCriticalエラーがあるかを判定
  static bool get hasAnyCriticalErrors {
    final validationResults = validateAllDomainConfigs();
    final runtimeErrors = validateConfiguration();

    // ランタイム設定のCriticalエラーチェック
    final hasCriticalRuntimeErrors = runtimeErrors.any((error) =>
        error.contains('production環境') ||
        error.contains('形式が無効') ||
        error.contains('警告: production環境'));

    // 分野別設定のCriticalエラーチェック
    final hasCriticalDomainErrors = validationResults.values
        .any((errors) => errors.any((error) => _isCriticalError(error)));

    return hasCriticalRuntimeErrors || hasCriticalDomainErrors;
  }

  /// エラーがCriticalレベルかどうかを判定
  static bool _isCriticalError(String error) {
    return error.contains('データベース設定: バージョンが無効') ||
        error.contains('API設定: HotPepper APIタイムアウト値が無効') ||
        error.contains('位置情報設定: タイムアウト値が無効');
  }

  /// 分野別設定の検証
  static void _validateDomainConfigs(List<String> errors) {
    // API設定の検証
    _validateApiConfigSettings(errors);

    // 位置情報設定の検証
    _validateLocationConfigSettings(errors);

    // 検索設定の検証
    _validateSearchConfigSettings(errors);

    // UI設定の検証
    _validateUiConfigSettings(errors);

    // データベース設定の検証
    _validateDatabaseConfigSettings(errors);
  }

  /// API設定の検証
  static void _validateApiConfigSettings(List<String> errors) {
    if (!ApiConfig.isValidTimeout(ApiConfig.hotpepperApiTimeout)) {
      errors.add('API設定: HotPepper APIタイムアウト値が無効です '
          '(${ApiConfig.hotpepperApiTimeout}秒)');
    }

    if (!ApiConfig.isValidRetryCount(ApiConfig.hotpepperApiRetryCount)) {
      errors.add('API設定: HotPepper APIリトライ回数が無効です '
          '(${ApiConfig.hotpepperApiRetryCount}回)');
    }

    if (!ApiConfig.isValidMaxResults(ApiConfig.hotpepperMaxResults)) {
      errors.add(
          'API設定: HotPepper API最大結果数が無効です (${ApiConfig.hotpepperMaxResults}件)');
    }
  }

  /// 位置情報設定の検証
  static void _validateLocationConfigSettings(List<String> errors) {
    if (!LocationConfig.isValidTimeout(LocationConfig.defaultTimeoutSeconds)) {
      errors.add(
          '位置情報設定: タイムアウト値が無効です (${LocationConfig.defaultTimeoutSeconds}秒)');
    }

    if (!LocationConfig.isValidRadius(LocationConfig.defaultLocationRadius)) {
      errors
          .add('位置情報設定: 検索半径が無効です (${LocationConfig.defaultLocationRadius}m)');
    }

    if (!LocationConfig.isValidUpdateInterval(
        LocationConfig.locationUpdateInterval)) {
      errors
          .add('位置情報設定: 更新間隔が無効です (${LocationConfig.locationUpdateInterval}秒)');
    }
  }

  /// 検索設定の検証
  static void _validateSearchConfigSettings(List<String> errors) {
    if (!SearchConfig.isValidRange(SearchConfig.defaultRange)) {
      errors.add('検索設定: 検索範囲が無効です (${SearchConfig.defaultRange})');
    }

    if (!SearchConfig.isValidCount(SearchConfig.defaultCount)) {
      errors.add('検索設定: 検索結果数が無効です (${SearchConfig.defaultCount}件)');
    }

    if (!SearchConfig.isValidKeyword(SearchConfig.defaultKeyword)) {
      errors.add('検索設定: デフォルトキーワードが無効です (${SearchConfig.defaultKeyword})');
    }
  }

  /// UI設定の検証
  static void _validateUiConfigSettings(List<String> errors) {
    if (!UiConfig.isValidPadding(UiConfig.defaultPadding)) {
      errors.add('UI設定: デフォルトパディングが無効です (${UiConfig.defaultPadding})');
    }

    if (!UiConfig.isValidBorderRadius(UiConfig.cardBorderRadius)) {
      errors.add('UI設定: カード角丸値が無効です (${UiConfig.cardBorderRadius})');
    }
  }

  /// データベース設定の検証
  static void _validateDatabaseConfigSettings(List<String> errors) {
    if (!DatabaseConfig.isValidDatabaseVersion(
        DatabaseConfig.databaseVersion)) {
      errors.add('データベース設定: バージョンが無効です (${DatabaseConfig.databaseVersion})');
    }

    if (!DatabaseConfig.isValidCacheSize(DatabaseConfig.cacheSize)) {
      errors.add('データベース設定: キャッシュサイズが無効です (${DatabaseConfig.cacheSize})');
    }

    if (!DatabaseConfig.isValidPageSize(DatabaseConfig.pageSize)) {
      errors.add('データベース設定: ページサイズが無効です (${DatabaseConfig.pageSize})');
    }
  }

  /// 全分野別設定の検証結果を取得
  static Map<String, List<String>> validateAllDomainConfigs() {
    final result = <String, List<String>>{};

    // 各分野別の検証
    result['api'] = [];
    _validateApiConfigSettings(result['api']!);

    result['location'] = [];
    _validateLocationConfigSettings(result['location']!);

    result['search'] = [];
    _validateSearchConfigSettings(result['search']!);

    result['ui'] = [];
    _validateUiConfigSettings(result['ui']!);

    result['database'] = [];
    _validateDatabaseConfigSettings(result['database']!);

    return result;
  }

  /// 設定の詳細情報を取得（デバッグ用）
  static Map<String, dynamic> get configurationDetails {
    return {
      'environment': EnvironmentConfig.current.name,
      'validationErrors': validateConfiguration(),
      'domainValidationErrors': validateAllDomainConfigs(),
      'isValid': isConfigurationValid,
      'hasCriticalErrors': hasCriticalErrors,
      'debugInfo': EnvironmentConfig.debugInfo,
    };
  }
}
