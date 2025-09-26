import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_food_app/presentation/widgets/search_filter_widget.dart';

void main() {
  group('SearchFilterWidget Tests', () {
    testWidgets('should display filter options', (tester) async {
      // Arrange
      int selectedRange = 3;
      int selectedCount = 10;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchFilterWidget(
            searchRange: selectedRange,
            resultCount: selectedCount,
            onRangeChanged: (value) {},
            onCountChanged: (value) {},
          ),
        ),
      ));

      // Assert
      expect(find.text('検索範囲'), findsOneWidget);
      expect(find.text('結果数'), findsOneWidget);
    });

    testWidgets('should display range options', (tester) async {
      // Arrange
      int selectedRange = 3;
      int selectedCount = 10;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchFilterWidget(
            searchRange: selectedRange,
            resultCount: selectedCount,
            onRangeChanged: (value) {},
            onCountChanged: (value) {},
          ),
        ),
      ));

      // Assert
      expect(find.text('300m'), findsOneWidget);
      expect(find.text('500m'), findsOneWidget);
      expect(find.text('1000m'), findsOneWidget);
      expect(find.text('2000m'), findsOneWidget);
      expect(find.text('3000m'), findsOneWidget);
    });

    testWidgets('should handle range selection', (tester) async {
      // Arrange
      int selectedRange = 3;
      int selectedCount = 10;
      int? newRange;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchFilterWidget(
            searchRange: selectedRange,
            resultCount: selectedCount,
            onRangeChanged: (value) {
              newRange = value;
            },
            onCountChanged: (value) {},
          ),
        ),
      ));

      // 500mを選択
      await tester.tap(find.text('500m'));
      await tester.pump();

      // Assert
      expect(newRange, 2);
    });

    testWidgets('should display count slider', (tester) async {
      // Arrange
      int selectedRange = 3;
      int selectedCount = 15;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchFilterWidget(
            searchRange: selectedRange,
            resultCount: selectedCount,
            onRangeChanged: (value) {},
            onCountChanged: (value) {},
          ),
        ),
      ));

      // Assert
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('15件'), findsOneWidget);
    });

    testWidgets('should handle count slider change', (tester) async {
      // Arrange
      int selectedRange = 3;
      int selectedCount = 10;
      int? newCount;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchFilterWidget(
            searchRange: selectedRange,
            resultCount: selectedCount,
            onRangeChanged: (value) {},
            onCountChanged: (value) {
              newCount = value;
            },
          ),
        ),
      ));

      // スライダーを動かす
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pump();

      // Assert
      expect(newCount, isNotNull);
      expect(newCount, greaterThan(10));
    });

    testWidgets('should show correct selected range', (tester) async {
      // Arrange & Act
      for (int range = 1; range <= 5; range++) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SearchFilterWidget(
              searchRange: range,
              resultCount: 10,
              onRangeChanged: (value) {},
              onCountChanged: (value) {},
            ),
          ),
        ));

        // Assert - 選択された範囲が正しく表示される
        final expectedTexts = ['300m', '500m', '1000m', '2000m', '3000m'];
        final selectedText = expectedTexts[range - 1];

        // 選択されたアイテムが視覚的に区別される
        expect(find.text(selectedText), findsOneWidget);
      }
    });
  });
}
