import '../../domain/entities/visit_record.dart';

/// 訪問記録データのローカルデータソースインターフェース
abstract class VisitRecordLocalDatasource {
  /// 訪問記録を挿入
  Future<void> insertVisitRecord(VisitRecord visitRecord);

  /// IDで訪問記録を取得
  Future<VisitRecord?> getVisitRecordById(String id);

  /// 全訪問記録を取得
  Future<List<VisitRecord>> getAllVisitRecords();

  /// 店舗IDで訪問記録を取得
  Future<List<VisitRecord>> getVisitRecordsByStoreId(String storeId);

  /// 訪問記録を更新
  Future<void> updateVisitRecord(VisitRecord visitRecord);

  /// 訪問記録を削除
  Future<void> deleteVisitRecord(String id);
}
