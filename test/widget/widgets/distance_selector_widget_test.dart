import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/distance_selector_widget.dart';

/// 距離選択ウィジェットの単体テスト（TDD）
///
/// Issue #124: 距離設定UIをFilterChipからSliderに変更
/// Material Design 3準拠のSlider距離選択UIをテスト

void main() {
  group('DistanceSelectorWidget - Slider UI', () {
    testWidgets('滑らかなSliderが正しく表示される', (WidgetTester tester) async {
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

      await tester.pumpAndSettle(); // アニメーション完了を待機

      // Assert
      expect(find.text('検索範囲'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(Container),
            matching: find.text('1000m'),
          ),
          findsOneWidget); // バッジ表示確認
      expect(find.text('300m'), findsOneWidget); // 範囲最小値確認
      expect(find.text('3000m'), findsOneWidget); // 範囲最大値確認

      // Sliderの設定値確認
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(1000.0));
      expect(slider.min, equals(300.0));
      expect(slider.max, equals(3000.0));
      expect(slider.divisions, equals(27)); // 細かい分割確認
    });

    testWidgets('滑らかなSliderドラッグ時にonChangedが正しく呼ばれる',
        (WidgetTester tester) async {
      // Arrange
      int? changedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3, // 1000m
              onChanged: (range) {
                changedRange = range;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Sliderで直接onChangeEndをシミュレート
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      // 500m近くの値でonChangeEndを呼び出し
      sliderWidget.onChangeEnd?.call(500.0);

      // Assert - _snapToValidValue()により500mに丸められ、range=2になる
      expect(changedRange, equals(2)); // 500m = range 2
    });

    testWidgets('異なる距離選択で滑らかなSlider値が正しく表示される', (WidgetTester tester) async {
      // Arrange & Act - 各範囲をテスト
      final testCases = [
        {'range': 1, 'expectedMeter': 300.0, 'expectedText': '300m'},
        {'range': 2, 'expectedMeter': 500.0, 'expectedText': '500m'},
        {'range': 3, 'expectedMeter': 1000.0, 'expectedText': '1000m'},
        {'range': 4, 'expectedMeter': 2000.0, 'expectedText': '2000m'},
        {'range': 5, 'expectedMeter': 3000.0, 'expectedText': '3000m'},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DistanceSelectorWidget(
                selectedRange: testCase['range'] as int,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle(); // アニメーション完了を待機

        // Assert
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, equals(testCase['expectedMeter']));
        // バッジ内の特定テキストを確認（Container内のテキスト）
        expect(
            find.descendant(
              of: find.byType(Container),
              matching: find.text(testCase['expectedText'] as String),
            ),
            findsOneWidget);
      }
    });

    testWidgets('Material Design 3のテーマが滑らかなSliderに適用される',
        (WidgetTester tester) async {
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

      await tester.pumpAndSettle(); // アニメーション完了を待機

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(SliderTheme), findsOneWidget); // カスタムテーマ適用確認
      expect(
          find.descendant(
            of: find.byType(Container),
            matching: find.text('2000m'),
          ),
          findsOneWidget); // バッジ表示確認

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(2000.0));
      expect(slider.divisions, equals(27));
    });

    testWidgets('滑らかなSliderのラベルとバッジが正しく表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3, // 1000m
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // アニメーション完了を待機

      // Assert
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.label, equals('1000m')); // Sliderラベル確認
      expect(
          find.descendant(
            of: find.byType(Container),
            matching: find.text('1000m'),
          ),
          findsOneWidget); // バッジテキスト確認
    });

    testWidgets('滑らかなSliderの値変換とスナップ機能が正しく動作する', (WidgetTester tester) async {
      // Arrange
      final changedValues = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3,
              onChanged: (range) {
                changedValues.add(range);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // アニメーション完了を待機

      // Act & Assert - 各距離に近い値でスナップ動作をテスト
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      final testValues = [320.0, 480.0, 950.0, 1800.0, 2900.0]; // 各有効値に近い値
      final expectedRanges = [1, 2, 3, 4, 5]; // スナップ後の期待値

      for (int i = 0; i < testValues.length; i++) {
        sliderWidget.onChangeEnd?.call(testValues[i]);
        expect(changedValues[i], equals(expectedRanges[i]));
      }
    });
  });
}
