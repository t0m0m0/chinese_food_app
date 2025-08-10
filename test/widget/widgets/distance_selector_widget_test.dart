import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/search_config.dart';
import 'package:chinese_food_app/presentation/widgets/distance_selector_widget.dart';

/// 距離選択ウィジェットの単体テスト（TDD）
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// Material Design 3準拠の距離選択UIをテスト

void main() {
  group('DistanceSelectorWidget', () {
    testWidgets('距離選択チップが正しく表示される', (WidgetTester tester) async {
      // Arrange
      const selectedRange = 3; // 1000m

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: selectedRange,
              onChanged: (range) {
                // テスト用のコールバック
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('検索範囲'), findsOneWidget);
      expect(find.text('300m'), findsOneWidget);
      expect(find.text('500m'), findsOneWidget);
      expect(find.text('1000m'), findsOneWidget);
      expect(find.text('2000m'), findsOneWidget);
      expect(find.text('3000m'), findsOneWidget);
      expect(find.text('現在の設定: 1000m'), findsOneWidget);

      // 1000mのチップが選択状態であることを確認
      final chip1000m = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '1000m'),
      );
      expect(chip1000m.selected, isTrue);
    });

    testWidgets('異なる距離選択時にonChangedが呼ばれる', (WidgetTester tester) async {
      // Arrange
      int selectedRange = 3; // 1000m
      int? changedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: selectedRange,
              onChanged: (range) {
                changedRange = range;
              },
            ),
          ),
        ),
      );

      // Act - 500mのチップをタップ
      await tester.tap(find.widgetWithText(FilterChip, '500m'));
      await tester.pump();

      // Assert
      expect(changedRange, equals(2)); // 500m = range 2
    });

    testWidgets('Material Design 3のテーマが適用される', (WidgetTester tester) async {
      // Arrange
      const selectedRange = 4; // 2000m

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: selectedRange,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(5)); // 5つの距離選択肢
      expect(find.text('現在の設定: 2000m'), findsOneWidget);

      // 2000mが選択されていることを確認
      final chip2000m = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '2000m'),
      );
      expect(chip2000m.selected, isTrue);
    });

    testWidgets('全ての距離オプションが正しく表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert - SearchConfig.rangeToMetersの全ての値が表示されることを確認
      for (final entry in SearchConfig.rangeToMeters.entries) {
        expect(find.text('${entry.value}m'), findsOneWidget);
      }

      // 300mが選択されていることを確認（selectedRange = 1）
      final chip300m = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '300m'),
      );
      expect(chip300m.selected, isTrue);
    });

    testWidgets('各距離オプションをタップしてコールバックをテスト', (WidgetTester tester) async {
      // Arrange
      int selectedRange = 3;
      final changedRanges = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: selectedRange,
              onChanged: (range) {
                changedRanges.add(range);
              },
            ),
          ),
        ),
      );

      // Act & Assert - 各距離オプションをタップ
      final expectedRanges = [1, 2, 4, 5]; // 現在選択済みの3以外
      final expectedTexts = ['300m', '500m', '2000m', '3000m'];

      for (int i = 0; i < expectedTexts.length; i++) {
        await tester.tap(find.widgetWithText(FilterChip, expectedTexts[i]));
        await tester.pump();

        expect(changedRanges[i], equals(expectedRanges[i]));
      }

      expect(changedRanges.length, equals(4));
    });
  });
}
