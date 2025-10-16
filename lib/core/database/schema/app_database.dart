import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

part 'app_database.g.dart';

// Drift警告を無効化（テスト環境および開発環境）
final bool _isDriftInitialized = (() {
  // テスト環境またはデバッグモードでは警告を無効化
  if (const bool.fromEnvironment('flutter.test', defaultValue: false) ||
      const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
      kDebugMode) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }
  return true;
})();

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get status => text().nullable()(); // nullable に変更
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class VisitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get storeId =>
      text().references(Stores, #id, onDelete: KeyAction.cascade)();
  TextColumn get visitedAt => text()();
  TextColumn get menu => text()();
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get storeId =>
      text().references(Stores, #id, onDelete: KeyAction.cascade)();
  TextColumn get visitId => text()
      .nullable()
      .references(VisitRecords, #id, onDelete: KeyAction.setNull)();
  TextColumn get filePath => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Stores, VisitRecords, Photos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.connection) {
    // 静的初期化により自動で設定済み
    assert(_isDriftInitialized);
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();

          // パフォーマンス用インデックス作成
          await customStatement(
              'CREATE INDEX idx_stores_lat_lng ON stores (lat, lng);');
          await customStatement(
              'CREATE INDEX idx_stores_status ON stores (status);');
          await customStatement(
              'CREATE INDEX idx_stores_created_at ON stores (created_at);');
          await customStatement(
              'CREATE INDEX idx_visit_records_store_id ON visit_records (store_id);');
          await customStatement(
              'CREATE INDEX idx_visit_records_visited_at ON visit_records (visited_at);');
          await customStatement(
              'CREATE INDEX idx_photos_store_id ON photos (store_id);');

          // 外部キー制約を有効化
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1 && to == 2) {
            await m.addColumn(stores, stores.imageUrl);
          }
          if (from == 2 && to == 3) {
            // statusカラムをnullableに変更するためテーブルを再作成
            await customStatement('''
              CREATE TABLE stores_new (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT NOT NULL,
                lat REAL NOT NULL,
                lng REAL NOT NULL,
                image_url TEXT,
                status TEXT,
                memo TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL
              );
            ''');

            await customStatement('''
              INSERT INTO stores_new
              SELECT id, name, address, lat, lng, image_url, status, memo, created_at
              FROM stores;
            ''');

            await customStatement('DROP TABLE stores;');
            await customStatement('ALTER TABLE stores_new RENAME TO stores;');

            // インデックスを再作成
            await customStatement(
                'CREATE INDEX idx_stores_lat_lng ON stores (lat, lng);');
            await customStatement(
                'CREATE INDEX idx_stores_status ON stores (status);');
            await customStatement(
                'CREATE INDEX idx_stores_created_at ON stores (created_at);');
          }
          if (from == 1 && to == 3) {
            // v1からv3への直接マイグレーション
            await m.addColumn(stores, stores.imageUrl);
            // statusカラムをnullableに変更
            await customStatement('''
              CREATE TABLE stores_new (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT NOT NULL,
                lat REAL NOT NULL,
                lng REAL NOT NULL,
                image_url TEXT,
                status TEXT,
                memo TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL
              );
            ''');

            await customStatement('''
              INSERT INTO stores_new
              SELECT id, name, address, lat, lng, image_url, status, memo, created_at
              FROM stores;
            ''');

            await customStatement('DROP TABLE stores;');
            await customStatement('ALTER TABLE stores_new RENAME TO stores;');

            // インデックスを再作成
            await customStatement(
                'CREATE INDEX idx_stores_lat_lng ON stores (lat, lng);');
            await customStatement(
                'CREATE INDEX idx_stores_status ON stores (status);');
            await customStatement(
                'CREATE INDEX idx_stores_created_at ON stores (created_at);');
          }
        },
        beforeOpen: (details) async {
          // 外部キー制約を有効化
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
