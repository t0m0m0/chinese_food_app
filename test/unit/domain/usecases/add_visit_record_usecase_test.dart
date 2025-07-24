import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/repositories/visit_record_repository.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';

import 'add_visit_record_usecase_test.mocks.dart';

@GenerateMocks([VisitRecordRepository])
void main() {
  late AddVisitRecordUsecase usecase;
  late MockVisitRecordRepository mockRepository;

  setUp(() {
    mockRepository = MockVisitRecordRepository();
    usecase = AddVisitRecordUsecase(mockRepository);
  });

  group('AddVisitRecordUsecase', () {
    test('should add visit record successfully', () async {
      // Arrange
      final visitRecord = VisitRecord(
        id: 'test-id',
        storeId: 'store-id',
        visitedAt: DateTime(2024, 1, 15, 12, 30),
        menu: 'チャーハン',
        memo: '美味しかった',
        createdAt: DateTime(2024, 1, 15, 20, 0),
      );

      when(mockRepository.insertVisitRecord(any))
          .thenAnswer((_) async => visitRecord);

      // Act
      final result = await usecase.call(
        storeId: 'store-id',
        visitedAt: DateTime(2024, 1, 15, 12, 30),
        menu: 'チャーハン',
        memo: '美味しかった',
      );

      // Assert
      expect(result.storeId, equals('store-id'));
      expect(result.menu, equals('チャーハン'));
      expect(result.memo, equals('美味しかった'));
      verify(mockRepository.insertVisitRecord(any)).called(1);
    });

    test('should generate unique id for visit record', () async {
      // Arrange
      when(mockRepository.insertVisitRecord(any))
          .thenAnswer((invocation) async {
        final visitRecord = invocation.positionalArguments[0] as VisitRecord;
        return visitRecord;
      });

      // Act
      final result1 = await usecase.call(
        storeId: 'store-id',
        visitedAt: DateTime(2024, 1, 15),
        menu: 'メニュー1',
        memo: 'メモ1',
      );

      final result2 = await usecase.call(
        storeId: 'store-id',
        visitedAt: DateTime(2024, 1, 16),
        menu: 'メニュー2',
        memo: 'メモ2',
      );

      // Assert
      expect(result1.id, isNotEmpty);
      expect(result2.id, isNotEmpty);
      expect(result1.id, isNot(equals(result2.id)));
    });

    test('should auto-set created time', () async {
      // Arrange
      final beforeCall = DateTime.now();

      when(mockRepository.insertVisitRecord(any))
          .thenAnswer((invocation) async {
        final visitRecord = invocation.positionalArguments[0] as VisitRecord;
        return visitRecord;
      });

      // Act
      final result = await usecase.call(
        storeId: 'store-id',
        visitedAt: DateTime(2024, 1, 15),
        menu: 'メニュー',
        memo: 'メモ',
      );

      final afterCall = DateTime.now();

      // Assert
      expect(
          result.createdAt
              .isAfter(beforeCall.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          result.createdAt.isBefore(afterCall.add(const Duration(seconds: 1))),
          isTrue);
    });
  });
}
