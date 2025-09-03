import 'package:drift/drift.dart';
import '../../core/database/schema/app_database.dart';
import '../../domain/entities/visit_record.dart' as entities;

/// 訪問記録データのローカルデータソースインターフェース
abstract class VisitRecordLocalDatasource {
  /// 訪問記録を挿入
  Future<void> insertVisitRecord(entities.VisitRecord visitRecord);

  /// IDで訪問記録を取得
  Future<entities.VisitRecord?> getVisitRecordById(String id);

  /// 全訪問記録を取得
  Future<List<entities.VisitRecord>> getAllVisitRecords();

  /// 店舗IDで訪問記録を取得
  Future<List<entities.VisitRecord>> getVisitRecordsByStoreId(String storeId);

  /// 訪問記録を更新
  Future<void> updateVisitRecord(entities.VisitRecord visitRecord);

  /// 訪問記録を削除
  Future<void> deleteVisitRecord(String id);
}

/// 訪問記録データのローカルデータソース実装
///
/// Driftを使用したSQLiteデータベースアクセスを提供
class VisitRecordLocalDatasourceImpl implements VisitRecordLocalDatasource {
  final AppDatabase _database;

  VisitRecordLocalDatasourceImpl(this._database);

  @override
  Future<List<entities.VisitRecord>> getAllVisitRecords() async {
    final query = _database.select(_database.visitRecords)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.visitedAt)]);

    final results = await query.get();
    return results.map((record) => _driftVisitRecordToEntity(record)).toList();
  }

  @override
  Future<List<entities.VisitRecord>> getVisitRecordsByStoreId(
      String storeId) async {
    final query = _database.select(_database.visitRecords)
      ..where((tbl) => tbl.storeId.equals(storeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.visitedAt)]);

    final results = await query.get();
    return results.map((record) => _driftVisitRecordToEntity(record)).toList();
  }

  @override
  Future<entities.VisitRecord?> getVisitRecordById(String id) async {
    final query = _database.select(_database.visitRecords)
      ..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _driftVisitRecordToEntity(result) : null;
  }

  @override
  Future<void> insertVisitRecord(entities.VisitRecord visitRecord) async {
    await _database
        .into(_database.visitRecords)
        .insert(_visitRecordToCompanion(visitRecord));
  }

  @override
  Future<void> updateVisitRecord(entities.VisitRecord visitRecord) async {
    await (_database.update(_database.visitRecords)
          ..where((tbl) => tbl.id.equals(visitRecord.id)))
        .write(_visitRecordToCompanion(visitRecord));
  }

  @override
  Future<void> deleteVisitRecord(String id) async {
    await (_database.delete(_database.visitRecords)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// VisitRecord エンティティを Drift Companion に変換
  VisitRecordsCompanion _visitRecordToCompanion(
      entities.VisitRecord visitRecord) {
    return VisitRecordsCompanion(
      id: Value(visitRecord.id),
      storeId: Value(visitRecord.storeId),
      visitedAt: Value(visitRecord.visitedAt.toIso8601String()),
      menu: Value(visitRecord.menu),
      memo: Value(visitRecord.memo ?? ''),
      createdAt: Value(visitRecord.createdAt.toIso8601String()),
    );
  }

  /// Drift VisitRecord を Entity に変換
  entities.VisitRecord _driftVisitRecordToEntity(VisitRecord record) {
    return entities.VisitRecord(
      id: record.id,
      storeId: record.storeId,
      visitedAt: DateTime.parse(record.visitedAt),
      menu: record.menu,
      memo: record.memo.isEmpty ? null : record.memo,
      createdAt: DateTime.parse(record.createdAt),
    );
  }
}
