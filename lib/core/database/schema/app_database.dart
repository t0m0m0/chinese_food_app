import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get status => text()();
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
  AppDatabase(super.connection);

  @override
  int get schemaVersion => 2;

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
        },
        beforeOpen: (details) async {
          // 外部キー制約を有効化
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
