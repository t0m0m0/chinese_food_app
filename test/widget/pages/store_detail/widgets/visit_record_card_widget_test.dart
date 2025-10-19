import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/widgets/visit_record_card_widget.dart';

void main() {
  group('VisitRecordCardWidget', () {
    testWidgets('訪問日時、メニュー、メモを表示する', (tester) async {
      // Arrange
      final visitRecord = VisitRecord(
        id: 'record-1',
        storeId: 'store-123',
        visitedAt: DateTime(2025, 10, 19, 14, 30),
        menu: '麻婆豆腐定食',
        memo: '辛さがちょうど良い',
        createdAt: DateTime(2025, 10, 19, 14, 35),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordCardWidget(visitRecord: visitRecord),
          ),
        ),
      );

      // Assert
      expect(find.text('麻婆豆腐定食'), findsOneWidget);
      expect(find.text('辛さがちょうど良い'), findsOneWidget);
      expect(find.textContaining('2025年10月19日'), findsOneWidget);
    });

    testWidgets('メモが空の場合、メモ欄を表示しない', (tester) async {
      // Arrange
      final visitRecord = VisitRecord(
        id: 'record-1',
        storeId: 'store-123',
        visitedAt: DateTime(2025, 10, 19, 14, 30),
        menu: '麻婆豆腐定食',
        memo: '',
        createdAt: DateTime(2025, 10, 19, 14, 35),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordCardWidget(visitRecord: visitRecord),
          ),
        ),
      );

      // Assert
      expect(find.text('麻婆豆腐定食'), findsOneWidget);
      // メモが空なので表示されない
      expect(find.byIcon(Icons.comment), findsNothing);
    });

    testWidgets('訪問日時が時刻まで含めて表示される', (tester) async {
      // Arrange
      final visitRecord = VisitRecord(
        id: 'record-1',
        storeId: 'store-123',
        visitedAt: DateTime(2025, 10, 19, 14, 30),
        menu: '麻婆豆腐定食',
        memo: '辛さがちょうど良い',
        createdAt: DateTime(2025, 10, 19, 14, 35),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitRecordCardWidget(visitRecord: visitRecord),
          ),
        ),
      );

      // Assert
      // 「2025年10月19日 14:30」の形式
      expect(find.textContaining('14:30'), findsOneWidget);
    });
  });
}
