import '../database_config.dart';

/// データベース設定管理を担当するManager
class DatabaseConfigManager {
  DatabaseConfigManager._(); // private constructor

  /// データベース設定の検証を実行
  static List<String> validate() {
    final errors = <String>[];

    if (!DatabaseConfig.isValidDatabaseVersion(DatabaseConfig.databaseVersion)) {
      errors.add('データベースバージョンが無効です: ${DatabaseConfig.databaseVersion}');
    }

    if (!DatabaseConfig.isValidCacheSize(DatabaseConfig.cacheSize)) {
      errors.add('データベースキャッシュサイズが無効です: ${DatabaseConfig.cacheSize}');
    }

    if (!DatabaseConfig.isValidPageSize(DatabaseConfig.pageSize)) {
      errors.add('データベースページサイズが無効です: ${DatabaseConfig.pageSize}');
    }

    return errors;
  }

  /// データベース設定情報を取得
  static Map<String, dynamic> getConfig() {
    return {
      'type': 'database',
      'databaseVersion': DatabaseConfig.databaseVersion,
      'cacheSize': DatabaseConfig.cacheSize,
      'pageSize': DatabaseConfig.pageSize,
      'databaseName': DatabaseConfig.databaseName,
      'enableForeignKeys': DatabaseConfig.enableForeignKeys,
    };
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'manager': 'DatabaseConfigManager',
      'config': getConfig(),
      'validationErrors': validate(),
    };
  }
}