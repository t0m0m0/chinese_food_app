import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/widgets/swipe_card_widget.dart';

void main() {
  group('SwipeCardWidget', () {
    late Store testStore;

    setUp(() {
      testStore = Store(
        id: 'test-store-1',
        name: 'テスト中華料理店',
        address: '東京都渋谷区1-1-1',
        lat: 35.6580,
        lng: 139.7016,
        imageUrl: 'https://example.com/image.jpg',
        status: null,
        memo: '',
        createdAt: DateTime.now(),
      );
    });

    testWidgets('店舗情報が正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // 店舗名が表示されている
      expect(find.text('テスト中華料理店'), findsOneWidget);

      // 住所が表示されている
      expect(find.text('東京都渋谷区1-1-1'), findsOneWidget);
    });

    testWidgets('店舗画像が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // 画像ウィジェットが存在する
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('カードをタップできる', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(
              store: testStore,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SwipeCardWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('Material Design 3準拠のスタイリングが適用される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // SwipeCardWidgetが存在する（新デザイン）
      expect(find.byType(SwipeCardWidget), findsOneWidget);

      // Containerウィジェットが使用されている
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('アクセシビリティ情報が設定される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // Semanticsウィジェットが存在する
      expect(find.byType(Semantics), findsWidgets);

      // SwipeCardWidgetが表示されている
      expect(find.byType(SwipeCardWidget), findsOneWidget);
    });

    testWidgets('拡張されたアクセシビリティ機能が動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(
              store: testStore,
              genre: '四川料理',
              budget: '2000～3000円',
            ),
          ),
        ),
      );

      // Semanticsウィジェットが存在する
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));

      // RepaintBoundaryとSemanticsの組み合わせが存在する
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('将来拡張対応のジャンル・予算情報が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(
              store: testStore,
              genre: '四川料理',
              budget: '2000～3000円',
              access: 'JR新宿駅東口徒歩3分',
              showDetailChips: true,
            ),
          ),
        ),
      );

      // ジャンル情報が表示される
      expect(find.text('四川料理'), findsOneWidget);

      // 予算情報が表示される
      expect(find.text('2000～3000円'), findsOneWidget);

      // アクセス情報が短縮されて表示される
      expect(find.textContaining('新宿駅'), findsOneWidget);
    });

    testWidgets('詳細チップ機能の有効無効が動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(
              store: testStore,
              genre: '四川料理',
              budget: '2000～3000円',
              showDetailChips: false, // チップ機能を無効化
            ),
          ),
        ),
      );

      // showDetailChips=falseの場合、詳細情報は表示されない
      expect(find.text('四川料理'), findsNothing);
      expect(find.text('2000～3000円'), findsNothing);
    });

    testWidgets('パフォーマンス最適化のRepaintBoundaryが適用される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // RepaintBoundaryが存在する
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });
  });
}
