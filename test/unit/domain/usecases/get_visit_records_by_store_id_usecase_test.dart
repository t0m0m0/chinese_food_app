import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/repositories/visit_record_repository.dart';
import 'package:chinese_food_app/domain/usecases/get_visit_records_by_store_id_usecase.dart';

import 'get_visit_records_by_store_id_usecase_test.mocks.dart';

@GenerateMocks([VisitRecordRepository])
void main() {
  late GetVisitRecordsByStoreIdUsecase usecase;
  late MockVisitRecordRepository mockRepository;

  setUp(() {
    mockRepository = MockVisitRecordRepository();
    usecase = GetVisitRecordsByStoreIdUsecase(mockRepository);
  });

  group('GetVisitRecordsByStoreIdUsecase', () {
    test('should return visit records for specified store id', () async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = [
        VisitRecord(
          id: 'visit-1',
          storeId: storeId,
          visitedAt: DateTime(2024, 1, 15, 12, 30),
          menu: 'チャーハン',
          memo: '美味しかった',
          createdAt: DateTime(2024, 1, 15, 20, 0),
        ),
        VisitRecord(
          id: 'visit-2',
          storeId: storeId,
          visitedAt: DateTime(2024, 1, 20, 18, 0),
          menu: '餃子定食',
          memo: 'ボリューム満点',
          createdAt: DateTime(2024, 1, 20, 22, 0),
        ),
      ];

      when(mockRepository.getVisitRecordsByStoreId(storeId))
          .thenAnswer((_) async => visitRecords);

      // Act
      final result = await usecase.call(storeId);

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, equals('visit-2')); // 新しい記録が最初
      expect(result[0].menu, equals('餃子定食'));
      expect(result[1].id, equals('visit-1')); // 古い記録が後
      expect(result[1].menu, equals('チャーハン'));
      verify(mockRepository.getVisitRecordsByStoreId(storeId)).called(1);
    });

    test('should return empty list when no visit records exist for store',
        () async {
      // Arrange
      const storeId = 'store-999';
      when(mockRepository.getVisitRecordsByStoreId(storeId))
          .thenAnswer((_) async => []);

      // Act
      final result = await usecase.call(storeId);

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getVisitRecordsByStoreId(storeId)).called(1);
    });

    test('should return records sorted by visit date (newest first)', () async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = [
        VisitRecord(
          id: 'visit-old',
          storeId: storeId,
          visitedAt: DateTime(2024, 1, 10, 12, 0),
          menu: '古い記録',
          memo: 'memo',
          createdAt: DateTime(2024, 1, 10, 20, 0),
        ),
        VisitRecord(
          id: 'visit-new',
          storeId: storeId,
          visitedAt: DateTime(2024, 1, 25, 12, 0),
          menu: '新しい記録',
          memo: 'memo',
          createdAt: DateTime(2024, 1, 25, 20, 0),
        ),
      ];

      when(mockRepository.getVisitRecordsByStoreId(storeId))
          .thenAnswer((_) async => visitRecords);

      // Act
      final result = await usecase.call(storeId);

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, equals('visit-new')); // 新しい記録が最初
      expect(result[1].id, equals('visit-old')); // 古い記録が後
    });
  });
}
