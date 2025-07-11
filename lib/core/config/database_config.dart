/// データベース関連の設定を管理するクラス
class DatabaseConfig {
  /// データベース設定
  static const String databaseName = 'machiapp.db';
  static const int databaseVersion = 2;

  /// データベースファイルパス設定
  static const String databasePath = 'databases';

  /// データベースのテーブル設定
  static const List<String> tableNames = [
    'stores',
    'visit_records',
    'photos',
  ];

  /// Foreign Key制約設定
  static const bool enableForeignKeys = true;

  /// WALモード設定（パフォーマンス向上）
  static const bool enableWalMode = true;

  /// 同期設定
  static const String synchronousMode = 'NORMAL'; // OFF, NORMAL, FULL

  /// キャッシュ設定
  static const int cacheSize = 1000; // ページ数
  static const int pageSize = 4096; // バイト

  /// トランザクション設定
  static const int transactionTimeout = 30; // 秒
  static const int maxTransactionRetries = 3;

  /// バックアップ設定
  static const bool enableAutoBackup = true;
  static const int backupInterval = 24; // 時間
  static const int maxBackupFiles = 7;

  /// インデックス設定
  static const List<String> optimizedIndexes = [
    'idx_stores_lat_lng',
    'idx_stores_status',
    'idx_visit_records_store_id',
    'idx_visit_records_visited_at',
    'idx_photos_store_id',
    'idx_photos_visit_id',
  ];

  /// データベースの整合性チェック設定
  static const bool enableIntegrityCheck = true;
  static const int integrityCheckInterval = 7; // 日

  /// バキューム設定
  static const bool enableAutoVacuum = true;
  static const int vacuumInterval = 30; // 日

  /// 設定値の妥当性チェック
  static bool isValidDatabaseVersion(int version) {
    return version > 0 && version <= 100;
  }

  /// 設定値の妥当性チェック
  static bool isValidCacheSize(int size) {
    return size >= 100 && size <= 10000;
  }

  /// 設定値の妥当性チェック
  static bool isValidPageSize(int size) {
    return [1024, 2048, 4096, 8192, 16384, 32768, 65536].contains(size);
  }

  /// 設定値の妥当性チェック
  static bool isValidTransactionTimeout(int timeout) {
    return timeout >= 1 && timeout <= 300;
  }

  /// 設定値の妥当性チェック
  static bool isValidMaxRetries(int retries) {
    return retries >= 0 && retries <= 10;
  }

  /// 設定値の妥当性チェック
  static bool isValidInterval(int interval) {
    return interval >= 1 && interval <= 168; // 1時間から1週間
  }

  /// 設定値の妥当性チェック
  static bool isValidBackupFiles(int files) {
    return files >= 1 && files <= 30;
  }

  /// テーブル名が有効かどうかを判定
  static bool isValidTableName(String tableName) {
    return tableNames.contains(tableName);
  }

  /// インデックス名が有効かどうかを判定
  static bool isValidIndexName(String indexName) {
    return optimizedIndexes.contains(indexName);
  }

  /// 同期モードが有効かどうかを判定
  static bool isValidSynchronousMode(String mode) {
    return ['OFF', 'NORMAL', 'FULL'].contains(mode.toUpperCase());
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'databaseName': databaseName,
      'databaseVersion': databaseVersion,
      'databasePath': databasePath,
      'tableNames': tableNames,
      'enableForeignKeys': enableForeignKeys,
      'enableWalMode': enableWalMode,
      'synchronousMode': synchronousMode,
      'cacheSize': cacheSize,
      'pageSize': pageSize,
      'transactionTimeout': transactionTimeout,
      'maxTransactionRetries': maxTransactionRetries,
      'enableAutoBackup': enableAutoBackup,
      'backupInterval': backupInterval,
      'maxBackupFiles': maxBackupFiles,
      'optimizedIndexes': optimizedIndexes,
      'enableIntegrityCheck': enableIntegrityCheck,
      'integrityCheckInterval': integrityCheckInterval,
      'enableAutoVacuum': enableAutoVacuum,
      'vacuumInterval': vacuumInterval,
    };
  }
}
