import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/distance_selector_widget.dart';

/// 距離選択ウィジェットの単体テスト（TDD）
///
/// Issue #124: 距離設定UIをFilterChipからSliderに変更
/// Material Design 3準拠のSlider距離選択UIをテスト

void main() {
  group('DistanceSelectorWidget - Slider UI', () {
    testWidgets('Sliderが正しく表示される', (WidgetTester tester) async {
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
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('現在の設定: 1000m'), findsOneWidget);

      // Sliderの値が1000.0であることを確認
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(1000.0));
      expect(slider.min, equals(300.0));
      expect(slider.max, equals(3000.0));
      expect(slider.divisions, equals(4));
    });

    testWidgets('Sliderドラッグ時にonChangedが正しく呼ばれる', (WidgetTester tester) async {
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

      // Act - Sliderを500m位置に変更
      final slider = find.byType(Slider);
      await tester.tap(slider);
      await tester.pump();

      // 500m位置への値変更をシミュレート
      final sliderWidget = tester.widget<Slider>(slider);
      sliderWidget.onChanged?.call(500.0);

      // Assert
      expect(changedRange, equals(2)); // 500m = range 2
    });

    testWidgets('異なる距離選択でSlider値が正しく表示される', (WidgetTester tester) async {
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

        // Assert
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, equals(testCase['expectedMeter']));
        expect(find.text('現在の設定: ${testCase['expectedText']}'), findsOneWidget);
      }
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
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('現在の設定: 2000m'), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(2000.0));
    });

    testWidgets('Sliderのラベルが正しく表示される', (WidgetTester tester) async {
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

      // Assert
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.label, equals('1000m'));
    });

    testWidgets('全ての距離値でSliderが正しく動作する', (WidgetTester tester) async {
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

      // Act & Assert - 各距離をテスト
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      final testValues = [300.0, 500.0, 1000.0, 2000.0, 3000.0];
      final expectedRanges = [1, 2, 3, 4, 5];

      for (int i = 0; i < testValues.length; i++) {
        sliderWidget.onChanged?.call(testValues[i]);
        expect(changedValues[i], equals(expectedRanges[i]));
      }
    });
  });
}
