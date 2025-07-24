import '../entities/visit_record.dart';
import '../repositories/visit_record_repository.dart';

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
