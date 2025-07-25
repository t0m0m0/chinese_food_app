import 'package:uuid/uuid.dart';

import '../entities/visit_record.dart';
import '../repositories/visit_record_repository.dart';

/// 訪問記録追加のユースケース
///
/// 店舗への訪問記録を作成し、データベースに保存する。
/// 自動的にUUIDを生成し、作成日時を設定する。
///
/// 例:
/// ```dart
/// final usecase = AddVisitRecordUsecase(repository);
/// final record = await usecase.call(
///   storeId: 'store-123',
///   visitedAt: DateTime.now(),
///   menu: 'チャーハン',
///   memo: '美味しかった',
/// );
/// ```
class AddVisitRecordUsecase {
  final VisitRecordRepository _repository;
  static const Uuid _uuid = Uuid();

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
