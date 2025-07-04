# 🗄️ Drift データベース開発ガイド

**本プロジェクトでは、Issue #37以降Driftを標準データベースORM として採用しています。**

## 📋 目次
- [概要](#概要)
- [主要機能・メリット](#主要機能メリット)
- [使用ガイド](#使用ガイド)
- [マイグレーション管理](#マイグレーション管理)
- [開発コマンド](#開発コマンド)
- [テスト実装](#テスト実装)
- [トラブルシューティング](#トラブルシューティング)
- [ベストプラクティス](#ベストプラクティス)

## 概要

Driftは型安全なDart用SQLiteラッパーで、Clean Architectureに準拠したデータアクセス層を提供します。Issue #37のDatabaseHelper完全移行により、本プロジェクトの標準ORM として採用されました。

## 主要機能・メリット

### ✅ 型安全性
- **コンパイル時SQLエラー検出**: 実行前にSQLの構文エラーを発見
- **型チェック**: String→StoreStatus enum等の自動変換
- **IDE補完**: 全てのクエリメソッドで自動補完サポート

### ✅ セキュリティ
- **SQL Injection防止**: パラメータ化クエリ自動適用
- **参照整合性**: Foreign Key制約による自動データ保護
- **トランザクション管理**: ACID特性保証

### ✅ パフォーマンス
- **最適化インデックス**: 地理座標・ステータス検索に特化
- **効率的クエリ**: Drift DSLによる最適化されたSQL生成
- **接続プール**: 自動リソース管理

### ✅ 開発体験
- **スキーマ管理**: バージョン管理・マイグレーション機能
- **コード生成**: build_runnerによる自動コード生成
- **デバッグ支援**: 詳細なエラーログとスタックトレース

## 使用ガイド

### 1. スキーマ定義

```dart
// lib/core/database/schema/app_database.dart
@DriftDatabase(tables: [Stores, VisitRecords, Photos])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await MigrationManager.createOptimizedIndexes(this);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      await MigrationManager.handleMigration(this, m, from, to);
    },
  );
}

// テーブル定義例
class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get status => intEnum<StoreStatus>()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 2. データアクセス層

```dart
// lib/data/datasources/store_local_datasource_drift.dart
class StoreLocalDatasourceDrift implements StoreLocalDatasource {
  final AppDatabase _database;
  
  const StoreLocalDatasourceDrift(this._database);

  @override
  Future<List<entities.Store>> getAllStores() async {
    final storeDataList = await _database.select(_database.stores).get();
    return storeDataList.map(_storeDataToEntity).toList();
  }

  @override
  Future<void> insertStore(entities.Store store) async {
    await _database.into(_database.stores).insert(_storeToCompanion(store));
  }

  @override
  Future<List<entities.Store>> getStoresByStatus(StoreStatus status) async {
    final query = _database.select(_database.stores)
      ..where((tbl) => tbl.status.equals(status.index))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    final storeDataList = await query.get();
    return storeDataList.map(_storeDataToEntity).toList();
  }

  // エンティティ変換メソッド
  entities.Store _storeDataToEntity(StoreData storeData) {
    return entities.Store(
      id: storeData.id,
      name: storeData.name,
      address: storeData.address,
      lat: storeData.lat,
      lng: storeData.lng,
      status: StoreStatus.values[storeData.status],
      memo: storeData.memo,
      createdAt: storeData.createdAt,
    );
  }
}
```

### 3. DI統合

```dart
// lib/core/di/app_di_container.dart
void _registerCommonServices() {
  // Drift database (singleton)
  _serviceContainer.registerSingleton<AppDatabase>(
    () => AppDatabase(_openDatabaseConnection()),
  );

  // Drift datasources
  _serviceContainer.register<StoreLocalDatasourceDrift>(() {
    return StoreLocalDatasourceDrift(
        _serviceContainer.resolve<AppDatabase>());
  });
}
```

## マイグレーション管理

### スキーマバージョン管理

```dart
// スキーマ変更時の手順
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 3; // インクリメント

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from <= 2) {
        // version 3への移行処理
        await m.addColumn(_database.stores, _database.stores.newColumn);
      }
    },
  );
}
```

### パフォーマンス最適化インデックス

```dart
// lib/core/database/migrations/migration_manager.dart
static Future<void> createOptimizedIndexes(AppDatabase database) async {
  await database.customStatement('''
    CREATE INDEX IF NOT EXISTS idx_stores_status ON stores (status);
    CREATE INDEX IF NOT EXISTS idx_stores_lat_lng ON stores (lat, lng);
    CREATE INDEX IF NOT EXISTS idx_stores_created_at ON stores (created_at);
    CREATE INDEX IF NOT EXISTS idx_visit_records_store_id ON visit_records (store_id);
    CREATE INDEX IF NOT EXISTS idx_visit_records_visited_at ON visit_records (visited_at);
    CREATE INDEX IF NOT EXISTS idx_photos_store_id ON photos (store_id);
    CREATE INDEX IF NOT EXISTS idx_photos_visit_id ON photos (visit_id);
  ''');
}
```

## 開発コマンド

### 基本コマンド

```bash
# コード生成（スキーマ変更後に実行）
dart run build_runner build --delete-conflicting-outputs

# ウォッチモード（開発時推奨）
dart run build_runner watch

# 生成ファイルクリーン
dart run build_runner clean

# 依存関係インストール
flutter pub get
```

### CI/CD用コマンド

```bash
# 最新の生成ファイルでビルド
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## テスト実装

### インメモリデータベーステスト

```dart
// test/unit/data/datasources/store_local_datasource_drift_test.dart
void main() {
  late AppDatabase database;
  late StoreLocalDatasourceDrift datasource;

  setUp(() {
    // インメモリデータベース使用
    database = AppDatabase(
      DatabaseConnection(NativeDatabase.memory())
    );
    datasource = StoreLocalDatasourceDrift(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('StoreLocalDatasourceDrift Tests', () {
    test('should insert store successfully', () async {
      // Given
      final store = createTestStore();

      // When
      await datasource.insertStore(store);

      // Then
      final stores = await datasource.getAllStores();
      expect(stores, hasLength(1));
      expect(stores.first.id, equals(store.id));
    });

    test('should handle foreign key constraints', () async {
      // Foreign Key制約のテスト
      final store = createTestStore();
      await datasource.insertStore(store);

      // 存在しない店舗IDでのテスト
      expect(
        () async => await visitRecordDatasource.insertVisitRecord(
          createTestVisitRecord(storeId: 'non-existent')
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. コード生成エラー

```bash
# 問題: build_runner fails with conflicts
[ERROR] Could not generate files for `drift|builder`.

# 解決:
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

#### 2. Foreign Key制約エラー

```dart
// 問題: SqliteException: FOREIGN KEY constraint failed
// 解決: 参照先レコードの存在確認
await database.select(database.stores)
  .where((tbl) => tbl.id.equals(visitRecord.storeId))
  .getSingleOrNull();
```

#### 3. Migration失敗

```dart
// 問題: Migration fails during schema upgrade
// 解決: MigrationManagerのログ確認
developer.log('Migration failed: $e', name: 'MigrationManager');

// テスト用データベースで検証
final testDb = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
```

#### 4. Web環境でのdart:js_interop エラー

```dart
// 問題: dart:js_interop is not available on this platform
// 解決: Web依存を削除し、Native Databaseのみ使用
DatabaseConnection _openDatabaseConnection() {
  // Web APIは使用しない（テスト環境互換性のため）
  return DatabaseConnection(NativeDatabase.createInBackground(
    File('app_db.sqlite'),
  ));
}
```

## ベストプラクティス

### 1. パフォーマンス最適化

```dart
// 良い例: インデックスを活用したクエリ
final query = _database.select(_database.stores)
  ..where((tbl) => tbl.status.equals(StoreStatus.wantToGo.index))
  ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

// 良い例: バッチ操作
await _database.batch((batch) {
  for (final store in stores) {
    batch.insert(_database.stores, _storeToCompanion(store));
  }
});
```

### 2. エラーハンドリング

```dart
// 良い例: 具体的な例外ハンドリング
try {
  await datasource.insertStore(store);
} on SqliteException catch (e) {
  if (e.message.contains('UNIQUE constraint failed')) {
    throw DuplicateStoreException('Store with ID ${store.id} already exists');
  }
  rethrow;
}
```

### 3. テスト設計

```dart
// 良い例: 包括的テストカバレッジ
group('Edge Cases', () {
  test('should handle null visit_id in photos', () async {
    final photo = createTestPhoto(visitId: null);
    await photoDatasource.insertPhoto(photo);
    // 検証...
  });

  test('should cascade delete when store is removed', () async {
    // Foreign Key制約テスト
  });
});
```

### 4. マイグレーション設計

```dart
// 良い例: 段階的マイグレーション
static Future<void> handleMigration(
  AppDatabase database, Migrator migrator, int from, int to) async {
  
  developer.log('Starting migration from $from to $to', name: 'Migration');
  
  if (from <= 1) {
    await _migrateToVersion2(migrator);
  }
  if (from <= 2) {
    await _migrateToVersion3(migrator);
  }
  
  await createOptimizedIndexes(database);
  developer.log('Migration completed successfully', name: 'Migration');
}
```

## 関連ドキュメント

- [Drift公式ドキュメント](https://drift.simonbinder.eu/)
- [プロジェクトのClean Architecture Guide](../CLAUDE.md#アーキテクチャ)
- [Issue #37: DatabaseHelper完全移行とDrift統合](https://github.com/t0m0m0/chinese_food_app/issues/37)

---

**本ガイドは継続的に更新されます。Drift関連の質問や改善提案があれば、新しいIssueを作成してください。**

*Last updated: 2025-07-04*