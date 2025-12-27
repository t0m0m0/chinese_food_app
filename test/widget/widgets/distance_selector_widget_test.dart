import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/distance_selector_widget.dart';

/// 距離選択ウィジェットの単体テスト（TDD）
///
/// Issue #124: 距離設定UIをFilterChipからSliderに変更
/// Issue #246: 検索範囲を50kmまで拡張
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

      await tester.pumpAndSettle(); // アニメーション完了を待機

      // Assert
      expect(find.text('検索範囲'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(Container),
            matching: find.text('1km'),
          ),
          findsOneWidget); // バッジ表示確認（1000m → 1km）
      expect(find.text('300m'), findsOneWidget); // 範囲最小値確認
      expect(find.text('50km'), findsOneWidget); // 範囲最大値確認

      // Sliderの設定値確認（インデックスベース: 0-8）
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(2.0)); // 1000m = index 2
      expect(slider.min, equals(0.0));
      expect(slider.max, equals(8.0)); // 9段階: 0-8
      expect(slider.divisions, equals(8)); // 9段階
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

      await tester.pumpAndSettle();

      // Act - Sliderで直接onChangeEndをシミュレート
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      // index 1 (500m) でonChangeEndを呼び出し
      sliderWidget.onChangeEnd?.call(1.0);

      // Assert
      expect(changedRange, equals(2)); // 500m = API range 2
    });

    testWidgets('異なる距離選択でSlider値が正しく表示される', (WidgetTester tester) async {
      // Arrange & Act - 各範囲をテスト
      final testCases = [
        {'range': 1, 'expectedIndex': 0.0, 'expectedText': '300m'},
        {'range': 2, 'expectedIndex': 1.0, 'expectedText': '500m'},
        {'range': 3, 'expectedIndex': 2.0, 'expectedText': '1km'},
        {'range': 4, 'expectedIndex': 3.0, 'expectedText': '2km'},
        {'range': 5, 'expectedIndex': 4.0, 'expectedText': '3km'},
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
        expect(slider.value, equals(testCase['expectedIndex']));
        // バッジ内の特定テキストを確認（Container内のテキスト）
        expect(
            find.descendant(
              of: find.byType(Container),
              matching: find.text(testCase['expectedText'] as String),
            ),
            findsOneWidget);
      }
    });

    testWidgets('Material Design 3のテーマがSliderに適用される',
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
            matching: find.text('2km'),
          ),
          findsOneWidget); // バッジ表示確認

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(3.0)); // 2000m = index 3
      expect(slider.divisions, equals(8));
    });

    testWidgets('Sliderのラベルとバッジが正しく表示される', (WidgetTester tester) async {
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
      expect(slider.label, equals('1km')); // Sliderラベル確認
      expect(
          find.descendant(
            of: find.byType(Container),
            matching: find.text('1km'),
          ),
          findsOneWidget); // バッジテキスト確認
    });

    testWidgets('Slider値がAPIマッピングに正しく変換される', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Act & Assert - インデックス値がAPIレンジに正しくマッピングされることをテスト
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      // 各インデックスでテスト
      final testCases = [
        {'index': 0.0, 'expectedRange': 1}, // 300m
        {'index': 1.0, 'expectedRange': 2}, // 500m
        {'index': 2.0, 'expectedRange': 3}, // 1000m
        {'index': 3.0, 'expectedRange': 4}, // 2000m
        {'index': 4.0, 'expectedRange': 5}, // 3000m
        {'index': 5.0, 'expectedRange': 5}, // 5000m → API max 5
        {'index': 8.0, 'expectedRange': 5}, // 50000m → API max 5
      ];

      for (final testCase in testCases) {
        changedValues.clear();
        sliderWidget.onChangeEnd?.call(testCase['index'] as double);
        expect(changedValues.last, equals(testCase['expectedRange']));
      }
    });

    testWidgets('広域検索時にonMetersChangedが呼ばれる', (WidgetTester tester) async {
      // Arrange
      int? changedMeters;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3,
              onChanged: (_) {},
              onMetersChanged: (meters) {
                changedMeters = meters;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - 広域検索範囲（5km = index 5）を選択
      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);
      sliderWidget.onChangeEnd?.call(5.0);

      // Assert
      expect(changedMeters, equals(5000)); // 5km = 5000m
    });

    testWidgets('初期状態でSliderが折りたたまれている', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - SizeTransitionは存在するが、Sliderは見えない状態（sizeFactor=0）
      expect(find.byType(SizeTransition), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('ヘッダータップでSliderが展開される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - ヘッダーをタップして展開
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - Sliderが表示されていることを確認
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('300m'), findsOneWidget); // 範囲ラベル
      expect(find.text('50km'), findsOneWidget); // 範囲ラベル（3000m → 50km）
    });

    testWidgets('展開後、再度タップで折りたたまれる', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - まず展開
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 展開されていることを確認
      expect(find.byType(Slider), findsOneWidget);

      // 再度タップして折りたたみ
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - SizeTransitionは存在するが、Sliderは見えない状態
      expect(find.byType(SizeTransition), findsOneWidget);
    });

    testWidgets('広域検索選択時に注意書きが表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceSelectorWidget(
              selectedRange: 6, // 5km（広域検索）
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - ヘッダーをタップして展開
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 広域検索の注意書きが表示される
      expect(find.text('広域検索: 複数回のAPI検索を行います'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
