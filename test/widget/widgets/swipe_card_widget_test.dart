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

      // Cardウィジェットが存在する
      expect(find.byType(Card), findsOneWidget);

      // 丸角処理が適用されている
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('アクセシビリティ情報が設定される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCardWidget(store: testStore),
          ),
        ),
      );

      // セマンティクス情報が適切に設定されている
      expect(find.bySemanticsLabel('テスト中華料理店の店舗カード'), findsOneWidget);
    });
  });
}
