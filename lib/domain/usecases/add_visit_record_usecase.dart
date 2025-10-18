import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../entities/visit_record.dart';
import '../entities/store.dart';
import '../repositories/visit_record_repository.dart';
import '../repositories/store_repository.dart';

/// 訪問記録追加のユースケース
///
/// 店舗への訪問記録を作成し、データベースに保存する。
/// 自動的にUUIDを生成し、作成日時を設定する。
/// 店舗がローカルDBに存在しない場合は、自動的に店舗を保存する。
///
/// 例:
/// ```dart
/// final usecase = AddVisitRecordUsecase(visitRecordRepository, storeRepository);
/// final record = await usecase.call(
///   store: store, // APIから取得した店舗データ
///   storeId: 'store-123',
///   visitedAt: DateTime.now(),
///   menu: 'チャーハン',
///   memo: '美味しかった',
/// );
/// ```
class AddVisitRecordUsecase {
  final VisitRecordRepository _visitRecordRepository;
  final StoreRepository _storeRepository;
  static const Uuid _uuid = Uuid();

  AddVisitRecordUsecase(
    this._visitRecordRepository,
    this._storeRepository,
  );

  Future<VisitRecord> call({
    Store? store,
    required String storeId,
    required DateTime visitedAt,
    required String menu,
    required String memo,
  }) async {
    // 店舗が渡された場合、ローカルDBに存在するか確認
    if (store != null) {
      try {
        final existingStore = await _storeRepository.getStoreById(storeId);
        if (existingStore == null) {
          // 店舗が存在しない場合は自動的に保存
          // デバッグログ: 保存しようとしている店舗情報
          debugPrint(
              'DEBUG: Saving store - id: ${store.id}, name: ${store.name}, status: ${store.status}, memo: ${store.memo}');
          await _storeRepository.insertStore(store);
          debugPrint('DEBUG: Store saved successfully');
        } else {
          debugPrint('DEBUG: Store already exists - id: $storeId');
        }
      } catch (e, stackTrace) {
        debugPrint('DEBUG: Store save failed - Error: $e');
        debugPrint('DEBUG: StackTrace: $stackTrace');
        throw Exception('店舗の自動保存に失敗しました: $e');
      }
    }

    final visitRecord = VisitRecord(
      id: _uuid.v4(),
      storeId: storeId,
      visitedAt: visitedAt,
      menu: menu,
      memo: memo,
      createdAt: DateTime.now(),
    );

    try {
      debugPrint('DEBUG: Saving visit record - storeId: $storeId, menu: $menu');
      final result =
          await _visitRecordRepository.insertVisitRecord(visitRecord);
      debugPrint('DEBUG: Visit record saved successfully');
      return result;
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Visit record save failed - Error: $e');
      debugPrint('DEBUG: StackTrace: $stackTrace');
      throw Exception('訪問記録の保存に失敗しました: $e');
    }
  }
}
