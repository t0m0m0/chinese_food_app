import 'package:uuid/uuid.dart';

import '../entities/visit_record.dart';
import '../repositories/visit_record_repository.dart';

class AddVisitRecordUsecase {
  final VisitRecordRepository _repository;
  final Uuid _uuid = const Uuid();

  AddVisitRecordUsecase(this._repository);

  Future<VisitRecord> call({
    required String storeId,
    required DateTime visitedAt,
    required String menu,
    required String memo,
  }) async {
    final visitRecord = VisitRecord(
      id: _uuid.v4(),
      storeId: storeId,
      visitedAt: visitedAt,
      menu: menu,
      memo: memo,
      createdAt: DateTime.now(),
    );

    return await _repository.insertVisitRecord(visitRecord);
  }
}
