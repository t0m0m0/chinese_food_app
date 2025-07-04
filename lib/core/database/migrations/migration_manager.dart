import 'dart:developer' as developer;
import '../schema/app_database.dart';

class MigrationManager {
  final AppDatabase _database;

  MigrationManager(this._database);

  Future<void> migrateFromVersion1To2() async {
    try {
      await _database
          .customStatement('ALTER TABLE stores ADD COLUMN image_url TEXT');
      developer.log('Migration from version 1 to 2 completed successfully',
          name: 'MigrationManager');
    } catch (e) {
      developer.log('Migration from version 1 to 2 failed: $e',
          name: 'MigrationManager');
      rethrow;
    }
  }

  Future<int> getCurrentSchemaVersion() async {
    return _database.schemaVersion;
  }

  Future<void> createPerformanceIndexes() async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_stores_lat_lng ON stores (lat, lng)',
      'CREATE INDEX IF NOT EXISTS idx_stores_status ON stores (status)',
      'CREATE INDEX IF NOT EXISTS idx_stores_created_at ON stores (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_visit_records_store_id ON visit_records (store_id)',
      'CREATE INDEX IF NOT EXISTS idx_visit_records_visited_at ON visit_records (visited_at)',
      'CREATE INDEX IF NOT EXISTS idx_photos_store_id ON photos (store_id)',
    ];

    try {
      for (final indexSql in indexes) {
        await _database.customStatement(indexSql);
      }
      developer.log('Performance indexes created successfully',
          name: 'MigrationManager');
    } catch (e) {
      developer.log('Failed to create performance indexes: $e',
          name: 'MigrationManager');
      rethrow;
    }
  }

  Future<void> enableForeignKeyConstraints() async {
    await _database.customStatement('PRAGMA foreign_keys = ON');
  }

  Future<bool> validateMigrationChain() async {
    try {
      // 基本的な整合性チェック
      final result =
          await _database.customSelect('PRAGMA integrity_check').get();
      final integrityResult = result.first.data.values.first as String;
      final isValid = integrityResult == 'ok';

      if (isValid) {
        developer.log('Migration chain validation passed',
            name: 'MigrationManager');
      } else {
        developer.log('Migration chain validation failed: $integrityResult',
            name: 'MigrationManager');
      }

      return isValid;
    } catch (e) {
      developer.log('Migration chain validation error: $e',
          name: 'MigrationManager');
      return false;
    }
  }
}
