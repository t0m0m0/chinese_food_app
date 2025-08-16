import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/widgets/store_map_widget.dart';

void main() {
  group('StoreMapWidget (WebView Implementation)', () {
    late Store testStore;
    late Store edgeCaseStore;

    setUp(() {
      testStore = Store(
        id: 'test-store-id',
        name: 'テスト中華店',
        address: '東京都新宿区歌舞伎町1-1-1',
        lat: 35.6938,
        lng: 139.7034,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );

      // 境界値でテスト
      edgeCaseStore = Store(
        id: 'test_store_edge',
        name: 'エッジケース店舗',
        address: '境界値テスト場所',
        lat: 90.0, // 有効な緯度の境界値
        lng: 180.0, // 有効な経度の境界値
        status: StoreStatus.wantToGo,
        memo: null,
        createdAt: DateTime.now(),
      );
    });

    group('WebView Map Display Tests', () {
      testWidgets(
          'should display Stack with WebViewMapWidget and FloatingActionButton',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // StoreMapWidgetのStackとFloatingActionButtonが表示されることを確認
        expect(find.byType(Stack), findsAtLeastNWidgets(1));
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // 外部地図アプリ起動ボタンが表示されることを確認
        expect(find.byIcon(Icons.navigation), findsOneWidget);
        expect(find.byTooltip('外部地図アプリで開く'), findsOneWidget);
      });

      testWidgets('should have navigation button with proper semantics',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // Semanticsラベルが正しく設定されていることを確認
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));

        // NavigationアイコンとTooltipが存在することを確認
        expect(find.byIcon(Icons.navigation), findsOneWidget);
        expect(find.byTooltip('外部地図アプリで開く'), findsOneWidget);
      });

      testWidgets('should handle navigation button tap without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // ナビゲーションボタンをタップ（実際の外部アプリ起動はしない）
        final navigationButton = find.byType(FloatingActionButton);
        expect(navigationButton, findsOneWidget);

        await tester.tap(navigationButton);
        await tester.pump();

        // エラーが発生せずボタンが正常に機能することを確認
        expect(navigationButton, findsOneWidget);
      });
    });

    group('Widget Structure Tests', () {
      testWidgets('should have proper widget hierarchy',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // 基本的なウィジェット構造の確認
        expect(find.byType(Stack), findsAtLeastNWidgets(1));
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(Positioned), findsOneWidget);
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });

      testWidgets('should maintain proper positioning',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // Positionedウィジェットで適切な位置に配置されていることを確認
        final positioned = find.byType(Positioned);
        expect(positioned, findsOneWidget);

        final positionedWidget = tester.widget<Positioned>(positioned);
        expect(positionedWidget.top, equals(16.0));
        expect(positionedWidget.right, equals(16.0));
      });
    });

    group('Store Data Integration Tests', () {
      testWidgets('should work with different store data',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: edgeCaseStore),
          ),
        ));

        // エッジケースストアでもウィジェットが正常に動作することを確認
        expect(find.byType(Stack), findsAtLeastNWidgets(1));
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.navigation), findsOneWidget);
      });

      testWidgets('should handle store with boundary coordinate values',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: edgeCaseStore),
          ),
        ));

        // 境界値座標でもエラーが発生しないことを確認
        expect(find.byType(Stack), findsAtLeastNWidgets(1));
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // ナビゲーションボタンタップテスト
        final navigationButton = find.byType(FloatingActionButton);
        await tester.tap(navigationButton);
        await tester.pump();

        // エラーなく処理されることを確認
        expect(navigationButton, findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should provide proper accessibility support',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // アクセシビリティ要素の確認
        expect(find.byTooltip('外部地図アプリで開く'), findsOneWidget);

        // Semanticsラベルが適切に設定されていることを確認
        final semanticsList = find.byType(Semantics);
        expect(semanticsList, findsAtLeastNWidgets(1));

        // ラベル付きSemanticsウィジェットの存在を確認
        bool hasLabeledSemantics = false;
        for (int i = 0; i < semanticsList.evaluate().length; i++) {
          final semantics = tester.widget<Semantics>(semanticsList.at(i));
          if (semantics.properties.label != null &&
              semantics.properties.label!.contains('ナビゲーション')) {
            hasLabeledSemantics = true;
            break;
          }
        }
        expect(hasLabeledSemantics, isTrue);
      });

      testWidgets('should be interactive and focusable',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ));

        // FloatingActionButtonがインタラクティブであることを確認
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        // ボタンが有効であることを確認
        final fabWidget = tester.widget<FloatingActionButton>(fab);
        expect(fabWidget.onPressed, isNotNull);
      });
    });
  });
}
