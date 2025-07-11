import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/database_config.dart';

void main() {
  group('DatabaseConfig Tests', () {
    test('should have correct default values', () {
      expect(DatabaseConfig.databaseName, 'machiapp.db');
      expect(DatabaseConfig.databaseVersion, 2);
      expect(DatabaseConfig.databasePath, 'databases');
      expect(DatabaseConfig.enableForeignKeys, true);
      expect(DatabaseConfig.enableWalMode, true);
      expect(DatabaseConfig.synchronousMode, 'NORMAL');
      expect(DatabaseConfig.cacheSize, 1000);
      expect(DatabaseConfig.pageSize, 4096);
      expect(DatabaseConfig.transactionTimeout, 30);
      expect(DatabaseConfig.maxTransactionRetries, 3);
      expect(DatabaseConfig.enableAutoBackup, true);
      expect(DatabaseConfig.backupInterval, 24);
      expect(DatabaseConfig.maxBackupFiles, 7);
      expect(DatabaseConfig.enableIntegrityCheck, true);
      expect(DatabaseConfig.integrityCheckInterval, 7);
      expect(DatabaseConfig.enableAutoVacuum, true);
      expect(DatabaseConfig.vacuumInterval, 30);
    });

    test('should validate database version correctly', () {
      expect(DatabaseConfig.isValidDatabaseVersion(1), true);
      expect(DatabaseConfig.isValidDatabaseVersion(50), true);
      expect(DatabaseConfig.isValidDatabaseVersion(100), true);
      expect(DatabaseConfig.isValidDatabaseVersion(0), false);
      expect(DatabaseConfig.isValidDatabaseVersion(-1), false);
      expect(DatabaseConfig.isValidDatabaseVersion(101), false);
    });

    test('should validate cache size correctly', () {
      expect(DatabaseConfig.isValidCacheSize(100), true);
      expect(DatabaseConfig.isValidCacheSize(5000), true);
      expect(DatabaseConfig.isValidCacheSize(10000), true);
      expect(DatabaseConfig.isValidCacheSize(99), false);
      expect(DatabaseConfig.isValidCacheSize(-1), false);
      expect(DatabaseConfig.isValidCacheSize(10001), false);
    });

    test('should validate page size correctly', () {
      expect(DatabaseConfig.isValidPageSize(1024), true);
      expect(DatabaseConfig.isValidPageSize(2048), true);
      expect(DatabaseConfig.isValidPageSize(4096), true);
      expect(DatabaseConfig.isValidPageSize(8192), true);
      expect(DatabaseConfig.isValidPageSize(16384), true);
      expect(DatabaseConfig.isValidPageSize(32768), true);
      expect(DatabaseConfig.isValidPageSize(65536), true);
      expect(DatabaseConfig.isValidPageSize(512), false);
      expect(DatabaseConfig.isValidPageSize(65537), false);
    });

    test('should validate transaction timeout correctly', () {
      expect(DatabaseConfig.isValidTransactionTimeout(1), true);
      expect(DatabaseConfig.isValidTransactionTimeout(150), true);
      expect(DatabaseConfig.isValidTransactionTimeout(300), true);
      expect(DatabaseConfig.isValidTransactionTimeout(0), false);
      expect(DatabaseConfig.isValidTransactionTimeout(-1), false);
      expect(DatabaseConfig.isValidTransactionTimeout(301), false);
    });

    test('should validate max retries correctly', () {
      expect(DatabaseConfig.isValidMaxRetries(0), true);
      expect(DatabaseConfig.isValidMaxRetries(5), true);
      expect(DatabaseConfig.isValidMaxRetries(10), true);
      expect(DatabaseConfig.isValidMaxRetries(-1), false);
      expect(DatabaseConfig.isValidMaxRetries(11), false);
    });

    test('should validate interval correctly', () {
      expect(DatabaseConfig.isValidInterval(1), true);
      expect(DatabaseConfig.isValidInterval(84), true);
      expect(DatabaseConfig.isValidInterval(168), true);
      expect(DatabaseConfig.isValidInterval(0), false);
      expect(DatabaseConfig.isValidInterval(-1), false);
      expect(DatabaseConfig.isValidInterval(169), false);
    });

    test('should validate backup files correctly', () {
      expect(DatabaseConfig.isValidBackupFiles(1), true);
      expect(DatabaseConfig.isValidBackupFiles(15), true);
      expect(DatabaseConfig.isValidBackupFiles(30), true);
      expect(DatabaseConfig.isValidBackupFiles(0), false);
      expect(DatabaseConfig.isValidBackupFiles(-1), false);
      expect(DatabaseConfig.isValidBackupFiles(31), false);
    });

    test('should validate table name correctly', () {
      expect(DatabaseConfig.isValidTableName('stores'), true);
      expect(DatabaseConfig.isValidTableName('visit_records'), true);
      expect(DatabaseConfig.isValidTableName('photos'), true);
      expect(DatabaseConfig.isValidTableName('invalid_table'), false);
    });

    test('should validate index name correctly', () {
      expect(DatabaseConfig.isValidIndexName('idx_stores_lat_lng'), true);
      expect(DatabaseConfig.isValidIndexName('idx_stores_status'), true);
      expect(
          DatabaseConfig.isValidIndexName('idx_visit_records_store_id'), true);
      expect(DatabaseConfig.isValidIndexName('idx_visit_records_visited_at'),
          true);
      expect(DatabaseConfig.isValidIndexName('idx_photos_store_id'), true);
      expect(DatabaseConfig.isValidIndexName('idx_photos_visit_id'), true);
      expect(DatabaseConfig.isValidIndexName('invalid_index'), false);
    });

    test('should validate synchronous mode correctly', () {
      expect(DatabaseConfig.isValidSynchronousMode('OFF'), true);
      expect(DatabaseConfig.isValidSynchronousMode('NORMAL'), true);
      expect(DatabaseConfig.isValidSynchronousMode('FULL'), true);
      expect(DatabaseConfig.isValidSynchronousMode('off'), true);
      expect(DatabaseConfig.isValidSynchronousMode('normal'), true);
      expect(DatabaseConfig.isValidSynchronousMode('full'), true);
      expect(DatabaseConfig.isValidSynchronousMode('INVALID'), false);
    });

    test('should provide comprehensive debug info', () {
      final debugInfo = DatabaseConfig.debugInfo;

      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo['databaseName'], isA<String>());
      expect(debugInfo['databaseVersion'], isA<int>());
      expect(debugInfo['databasePath'], isA<String>());
      expect(debugInfo['tableNames'], isA<List>());
      expect(debugInfo['enableForeignKeys'], isA<bool>());
      expect(debugInfo['enableWalMode'], isA<bool>());
      expect(debugInfo['synchronousMode'], isA<String>());
      expect(debugInfo['cacheSize'], isA<int>());
      expect(debugInfo['pageSize'], isA<int>());
      expect(debugInfo['transactionTimeout'], isA<int>());
      expect(debugInfo['maxTransactionRetries'], isA<int>());
      expect(debugInfo['enableAutoBackup'], isA<bool>());
      expect(debugInfo['backupInterval'], isA<int>());
      expect(debugInfo['maxBackupFiles'], isA<int>());
      expect(debugInfo['optimizedIndexes'], isA<List>());
      expect(debugInfo['enableIntegrityCheck'], isA<bool>());
      expect(debugInfo['integrityCheckInterval'], isA<int>());
      expect(debugInfo['enableAutoVacuum'], isA<bool>());
      expect(debugInfo['vacuumInterval'], isA<int>());
    });

    test('should have correct table names list', () {
      final tableNames = DatabaseConfig.tableNames;

      expect(tableNames, contains('stores'));
      expect(tableNames, contains('visit_records'));
      expect(tableNames, contains('photos'));
      expect(tableNames.length, 3);
    });

    test('should have correct optimized indexes list', () {
      final optimizedIndexes = DatabaseConfig.optimizedIndexes;

      expect(optimizedIndexes, contains('idx_stores_lat_lng'));
      expect(optimizedIndexes, contains('idx_stores_status'));
      expect(optimizedIndexes, contains('idx_visit_records_store_id'));
      expect(optimizedIndexes, contains('idx_visit_records_visited_at'));
      expect(optimizedIndexes, contains('idx_photos_store_id'));
      expect(optimizedIndexes, contains('idx_photos_visit_id'));
      expect(optimizedIndexes.length, 6);
    });

    test('should have correct performance settings', () {
      expect(DatabaseConfig.enableWalMode, true);
      expect(DatabaseConfig.synchronousMode, 'NORMAL');
      expect(DatabaseConfig.cacheSize, 1000);
      expect(DatabaseConfig.pageSize, 4096);
    });

    test('should have correct backup settings', () {
      expect(DatabaseConfig.enableAutoBackup, true);
      expect(DatabaseConfig.backupInterval, 24);
      expect(DatabaseConfig.maxBackupFiles, 7);
    });

    test('should have correct maintenance settings', () {
      expect(DatabaseConfig.enableIntegrityCheck, true);
      expect(DatabaseConfig.integrityCheckInterval, 7);
      expect(DatabaseConfig.enableAutoVacuum, true);
      expect(DatabaseConfig.vacuumInterval, 30);
    });
  });
}
