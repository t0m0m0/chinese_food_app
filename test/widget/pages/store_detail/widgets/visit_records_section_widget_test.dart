import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/widgets/visit_records_section_widget.dart';

void main() {
  group('VisitRecordsSectionWidget', () {
    testWidgets('訪問記録がない場合、空状態メッセージを表示する', (tester) async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = <VisitRecord>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordsSectionWidget(
              storeId: storeId,
              visitRecords: visitRecords,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('まだ訪問記録がありません'), findsOneWidget);
    });

    testWidgets('訪問記録が1件ある場合、訪問回数とリストを表示する', (tester) async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = [
        VisitRecord(
          id: 'record-1',
          storeId: storeId,
          visitedAt: DateTime(2025, 10, 19, 14, 30),
          menu: '麻婆豆腐定食',
          memo: '辛さがちょうど良い',
          createdAt: DateTime(2025, 10, 19, 14, 35),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordsSectionWidget(
              storeId: storeId,
              visitRecords: visitRecords,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('📝 訪問記録 (1回)'), findsOneWidget);
      expect(find.text('麻婆豆腐定食'), findsOneWidget);
      expect(find.text('辛さがちょうど良い'), findsOneWidget);
    });

    testWidgets('訪問記録が複数ある場合、すべて表示する', (tester) async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = [
        VisitRecord(
          id: 'record-1',
          storeId: storeId,
          visitedAt: DateTime(2025, 10, 19, 14, 30),
          menu: '麻婆豆腐定食',
          memo: '辛さがちょうど良い',
          createdAt: DateTime(2025, 10, 19, 14, 35),
        ),
        VisitRecord(
          id: 'record-2',
          storeId: storeId,
          visitedAt: DateTime(2025, 10, 15, 12, 0),
          menu: 'チャーハン',
          memo: 'パラパラで美味しい',
          createdAt: DateTime(2025, 10, 15, 12, 30),
        ),
        VisitRecord(
          id: 'record-3',
          storeId: storeId,
          visitedAt: DateTime(2025, 10, 10, 18, 0),
          menu: '餃子セット',
          memo: '',
          createdAt: DateTime(2025, 10, 10, 18, 30),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordsSectionWidget(
              storeId: storeId,
              visitRecords: visitRecords,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('📝 訪問記録 (3回)'), findsOneWidget);
      expect(find.text('麻婆豆腐定食'), findsOneWidget);
      expect(find.text('チャーハン'), findsOneWidget);
      expect(find.text('餃子セット'), findsOneWidget);
    });

    testWidgets('訪問日時が正しいフォーマットで表示される', (tester) async {
      // Arrange
      const storeId = 'store-123';
      final visitRecords = [
        VisitRecord(
          id: 'record-1',
          storeId: storeId,
          visitedAt: DateTime(2025, 10, 19, 14, 30),
          menu: '麻婆豆腐定食',
          memo: '辛さがちょうど良い',
          createdAt: DateTime(2025, 10, 19, 14, 35),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordsSectionWidget(
              storeId: storeId,
              visitRecords: visitRecords,
            ),
          ),
        ),
      );

      // Assert
      // 日時は「2025年10月19日 14:30」の形式で表示される
      expect(find.textContaining('2025年10月19日'), findsOneWidget);
    });
  });
}
