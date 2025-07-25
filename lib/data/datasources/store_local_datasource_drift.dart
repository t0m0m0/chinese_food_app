import 'package:drift/drift.dart';
import '../../core/database/schema/app_database.dart';
import '../../domain/entities/store.dart' as entities;
import 'store_local_datasource.dart';

/// Drift版のローカルデータベースでの店舗データアクセス
class StoreLocalDatasourceDrift implements StoreLocalDatasource {
  final AppDatabase _database;

  StoreLocalDatasourceDrift(this._database);

  @override
  Future<void> insertStore(entities.Store store) async {
    await _database.into(_database.stores).insert(_storeToCompanion(store));
  }

  @override
  Future<void> updateStore(entities.Store store) async {
    await (_database.update(_database.stores)
          ..where((tbl) => tbl.id.equals(store.id)))
        .write(_storeToCompanion(store));
  }

  @override
  Future<void> deleteStore(String storeId) async {
    await (_database.delete(_database.stores)
          ..where((tbl) => tbl.id.equals(storeId)))
        .go();
  }

  @override
  Future<entities.Store?> getStoreById(String storeId) async {
    final query = _database.select(_database.stores)
      ..where((tbl) => tbl.id.equals(storeId));

    final result = await query.getSingleOrNull();
    return result != null ? _driftStoreToEntity(result) : null;
  }

  @override
  Future<List<entities.Store>> getAllStores() async {
    final query = _database.select(_database.stores)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  @override
  Future<List<entities.Store>> getStoresByStatus(
      entities.StoreStatus status) async {
    final query = _database.select(_database.stores)
      ..where((tbl) => tbl.status.equals(status.value))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  @override
  Future<List<entities.Store>> searchStores(String query) async {
    // SQLインジェクション対策：入力値検証とサニタイズ
    final sanitizedQuery = _sanitizeSearchQuery(query);
    if (sanitizedQuery.isEmpty) {
      return [];
    }

    // LIKE演算子用のパターン作成（ワイルドカードエスケープ済み）
    final escapedQuery = _escapeForLike(sanitizedQuery);
    final likePattern = '%$escapedQuery%';

    final searchQuery = _database.select(_database.stores)
      ..where((tbl) =>
          tbl.name.like(likePattern) |
          tbl.address.like(likePattern) |
          tbl.memo.like(likePattern))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await searchQuery.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  /// 検索クエリをサニタイズしてSQLインジェクションを防ぐ
  String _sanitizeSearchQuery(String query) {
    if (query.isEmpty) return query;

    // SQLインジェクション対策：危険な文字パターンを除去
    String sanitized = query
        .replaceAll(RegExp(r"[';]"), '') // クォートとセミコロンを除去
        .replaceAll(RegExp(r'--.*'), '') // SQLコメントを除去
        .replaceAll(RegExp(r'/\*.*?\*/'), '') // SQLブロックコメントを除去
        .trim();

    // 長すぎるクエリを制限（DoS攻撃防止）
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }

    return sanitized;
  }

  /// LIKE演算子用のワイルドカード文字をエスケープ
  String _escapeForLike(String query) {
    // SQLiteでは\はエスケープ文字として機能しないため、
    // 代替文字に置換してマッチングを行う
    return query
        .replaceAll('%', '[%]') // %をSQLiteの文字クラスでエスケープ
        .replaceAll('_', '[_]'); // _をSQLiteの文字クラスでエスケープ
  }

  /// Store エンティティを Drift Companion に変換
  StoresCompanion _storeToCompanion(entities.Store store) {
    return StoresCompanion(
      id: Value(store.id),
      name: Value(store.name),
      address: Value(store.address),
      lat: Value(store.lat),
      lng: Value(store.lng),
      imageUrl: Value(store.imageUrl),
      status: Value(store.status?.value ?? 'want_to_go'),
      memo: Value(store.memo ?? ''),
      createdAt: Value(store.createdAt.toIso8601String()),
    );
  }

  /// Drift Store を Entity に変換
  entities.Store _driftStoreToEntity(Store store) {
    return entities.Store(
      id: store.id,
      name: store.name,
      address: store.address,
      lat: store.lat,
      lng: store.lng,
      imageUrl: store.imageUrl,
      status: entities.StoreStatus.values.firstWhere(
        (s) => s.value == store.status,
        orElse: () => entities.StoreStatus.wantToGo,
      ),
      memo: store.memo.isEmpty ? null : store.memo,
      createdAt: DateTime.parse(store.createdAt),
    );
  }
}
