import '../api_config.dart';
import '../ui_config.dart';
import '../database_config.dart';
import '../location_config.dart';
import '../search_config.dart';

/// 設定検証のFacadeクラス
///
/// 各設定ドメインの検証を統合して提供
class ConfigValidatorFacade {
  /// すべての設定を検証
  static Map<String, List<String>> validateAll() {
    return {
      'api': _validateApiConfig(),
      'ui': _validateUiConfig(),
      'database': _validateDatabaseConfig(),
      'location': _validateLocationConfig(),
      'search': _validateSearchConfig(),
    };
  }

  /// API設定の検証
  static List<String> _validateApiConfig() {
    final errors = <String>[];

    // HotPepper API設定検証
    if (!ApiConfig.isValidTimeout(ApiConfig.hotpepperApiTimeout)) {
      errors.add('HotPepper APIタイムアウト値が無効: ${ApiConfig.hotpepperApiTimeout}');
    }

    if (!ApiConfig.isValidRetryCount(ApiConfig.hotpepperApiRetryCount)) {
      errors.add('HotPepper APIリトライ回数が無効: ${ApiConfig.hotpepperApiRetryCount}');
    }

    return errors;
  }

  /// UI設定の検証
  static List<String> _validateUiConfig() {
    final errors = <String>[];

    if (!UiConfig.isValidPadding(UiConfig.defaultPadding)) {
      errors.add('デフォルトパディング値が無効: ${UiConfig.defaultPadding}');
    }

    return errors;
  }

  /// データベース設定の検証
  static List<String> _validateDatabaseConfig() {
    final errors = <String>[];

    if (!DatabaseConfig.isValidDatabaseVersion(
        DatabaseConfig.databaseVersion)) {
      errors.add('データベースバージョンが無効: ${DatabaseConfig.databaseVersion}');
    }

    return errors;
  }

  /// ロケーション設定の検証
  static List<String> _validateLocationConfig() {
    final errors = <String>[];

    if (!LocationConfig.isValidTimeout(LocationConfig.defaultTimeoutSeconds)) {
      errors.add('ロケーションタイムアウトが無効: ${LocationConfig.defaultTimeoutSeconds}');
    }

    return errors;
  }

  /// 検索設定の検証
  static List<String> _validateSearchConfig() {
    final errors = <String>[];

    if (!SearchConfig.isValidRange(SearchConfig.defaultRange)) {
      errors.add('検索範囲が無効: ${SearchConfig.defaultRange}');
    }

    return errors;
  }
}
