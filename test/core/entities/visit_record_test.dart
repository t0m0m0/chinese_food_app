import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';

void main() {
  group('VisitRecord Entity Tests', () {
    test('should create VisitRecord entity with valid data', () {
      // Red: This test should fail initially - VisitRecord entity doesn't exist yet
      final visitRecord = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン + 餃子',
        memo: '美味しかった！また来たい',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(visitRecord.id, 'test-visit-id');
      expect(visitRecord.storeId, 'test-store-id');
      expect(visitRecord.visitedAt, DateTime(2025, 6, 23, 12, 0, 0));
      expect(visitRecord.menu, 'ラーメン + 餃子');
      expect(visitRecord.memo, '美味しかった！また来たい');
      expect(visitRecord.createdAt, DateTime(2025, 6, 23, 16, 0, 0));
    });

    test('should create VisitRecord entity with default memo', () {
      final visitRecord = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(visitRecord.memo, isEmpty);
    });

    test('should validate required fields', () {
      expect(
          () => VisitRecord(
                id: '',
                storeId: 'test-store-id',
                visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
                menu: 'ラーメン',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => VisitRecord(
                id: 'test-visit-id',
                storeId: '',
                visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
                menu: 'ラーメン',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => VisitRecord(
                id: 'test-visit-id',
                storeId: 'test-store-id',
                visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
                menu: '',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should validate visitedAt is not in the future', () {
      final futureDateTime = DateTime.now().add(const Duration(days: 1));

      expect(
          () => VisitRecord(
                id: 'test-visit-id',
                storeId: 'test-store-id',
                visitedAt: futureDateTime,
                menu: 'ラーメン',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should convert to and from JSON', () {
      final originalRecord = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン + 餃子',
        memo: '美味しかった！',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final json = originalRecord.toJson();
      final reconstructedRecord = VisitRecord.fromJson(json);

      expect(reconstructedRecord.id, originalRecord.id);
      expect(reconstructedRecord.storeId, originalRecord.storeId);
      expect(reconstructedRecord.visitedAt, originalRecord.visitedAt);
      expect(reconstructedRecord.menu, originalRecord.menu);
      expect(reconstructedRecord.memo, originalRecord.memo);
      expect(reconstructedRecord.createdAt, originalRecord.createdAt);
    });

    test('should support equality comparison', () {
      final record1 = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン',
        memo: '美味しかった！',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final record2 = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン',
        memo: '美味しかった！',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final record3 = VisitRecord(
        id: 'different-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン',
        memo: '美味しかった！',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(record1, equals(record2));
      expect(record1.hashCode, equals(record2.hashCode));
      expect(record1, isNot(equals(record3)));
    });

    test('should format menu display correctly', () {
      final record = VisitRecord(
        id: 'test-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2025, 6, 23, 12, 0, 0),
        menu: 'ラーメン + 餃子 + ビール',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(record.menu, 'ラーメン + 餃子 + ビール');
      expect(record.menu.length, greaterThan(0));
    });

    test('should validate menu length limit (100 characters)', () {
      // Test exactly 100 characters - should pass
      final validMenu = 'a' * 100;
      expect(
        () => VisitRecord(
          id: 'test-id',
          storeId: 'test-store-id',
          visitedAt: DateTime(2024, 1, 1),
          menu: validMenu,
          createdAt: DateTime(2024, 1, 1),
        ),
        returnsNormally,
      );

      // Test 101 characters - should throw
      final invalidMenu = 'a' * 101;
      expect(
        () => VisitRecord(
          id: 'test-id',
          storeId: 'test-store-id',
          visitedAt: DateTime(2024, 1, 1),
          menu: invalidMenu,
          createdAt: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate memo length limit (500 characters)', () {
      // Test exactly 500 characters - should pass
      final validMemo = 'a' * 500;
      expect(
        () => VisitRecord(
          id: 'test-id',
          storeId: 'test-store-id',
          visitedAt: DateTime(2024, 1, 1),
          menu: 'test menu',
          memo: validMemo,
          createdAt: DateTime(2024, 1, 1),
        ),
        returnsNormally,
      );

      // Test 501 characters - should throw
      final invalidMemo = 'a' * 501;
      expect(
        () => VisitRecord(
          id: 'test-id',
          storeId: 'test-store-id',
          visitedAt: DateTime(2024, 1, 1),
          menu: 'test menu',
          memo: invalidMemo,
          createdAt: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
