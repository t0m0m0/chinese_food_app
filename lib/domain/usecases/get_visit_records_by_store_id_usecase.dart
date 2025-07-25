import '../entities/visit_record.dart';
import '../repositories/visit_record_repository.dart';

/// 店舗別訪問記録取得のユースケース
///
/// 指定された店舗IDに関連する全ての訪問記録を取得する。
/// 結果は訪問日時の新しい順（降順）でソートされる。
///
/// 例:
/// ```dart
/// final usecase = GetVisitRecordsByStoreIdUsecase(repository);
/// final records = await usecase.call('store-123');
/// // records[0] が最新の訪問記録
/// ```
class GetVisitRecordsByStoreIdUsecase {
  final VisitRecordRepository _repository;

  GetVisitRecordsByStoreIdUsecase(this._repository);

  Future<List<VisitRecord>> call(String storeId) async {
    final visitRecords = await _repository.getVisitRecordsByStoreId(storeId);

    // 訪問日時の新しい順にソート
    visitRecords.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

    return visitRecords;
  }
}
