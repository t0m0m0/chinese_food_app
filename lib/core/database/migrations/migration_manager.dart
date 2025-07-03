import '../schema/app_database.dart';

class MigrationManager {
  final AppDatabase _database;

  MigrationManager(this._database);

  Future<void> migrateFromVersion1To2() async {
    await _database
        .customStatement('ALTER TABLE stores ADD COLUMN image_url TEXT');
  }

  Future<int> getCurrentSchemaVersion() async {
    return _database.schemaVersion;
  }

  Future<void> createPerformanceIndexes() async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_stores_lat_lng ON stores (lat, lng)',
      'CREATE INDEX IF NOT EXISTS idx_visit_records_store_id ON visit_records (store_id)',
      'CREATE INDEX IF NOT EXISTS idx_photos_store_id ON photos (store_id)',
    ];

    for (final indexSql in indexes) {
      await _database.customStatement(indexSql);
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
      return integrityResult == 'ok';
    } catch (e) {
      return false;
    }
  }
}
