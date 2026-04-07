import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/widgets/store_map_widget.dart';
import '../../../helpers/test_helpers.dart';

/// 地図タップ→外部アプリ起動テスト（#251）
///
/// StoreMapWidgetの外部アプリ連携UIを検証
void main() {
  late Store testStore;

  setUp(() {
    testStore = TestDataBuilders.createTestStore(
      id: 'map_test_1',
      name: 'テスト中華料理店',
      lat: 35.6762,
      lng: 139.6503,
    );
  });

  Widget buildTestWidget(Store store) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: StoreMapWidget(
            store: store,
            testMapWidget: Container(
              color: Colors.grey,
              child: const Center(child: Text('テスト地図')),
            ),
          ),
        ),
      ),
    );
  }

  group('StoreMapWidget UI表示', () {
    testWidgets('ナビゲーションボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      // ナビゲーション開始ボタンが存在する
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('マップアプリで開くボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      expect(find.text('マップアプリで開く'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('テスト用地図ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      expect(find.text('テスト地図'), findsOneWidget);
    });

    testWidgets('ナビボタンにアクセシビリティラベルがある', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      // Semanticsラベルの検証
      expect(
        find.bySemanticsLabel('外部地図アプリでナビゲーションを開始'),
        findsOneWidget,
      );
    });

    testWidgets('ナビボタンのtooltipが正しい', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, 'ナビを開始');
    });

    testWidgets('ナビボタンがタップ可能', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      // タップしてもクラッシュしないことを確認
      // （実際のurl_launcherはテスト環境では動作しないが、エラーにはならない）
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
    });

    testWidgets('マップアプリで開くボタンがタップ可能', (tester) async {
      await tester.pumpWidget(buildTestWidget(testStore));
      await tester.pump();

      await tester.tap(find.text('マップアプリで開く'));
      await tester.pump();
    });

    testWidgets('異なる座標の店舗でもウィジェットが正しく表示される', (tester) async {
      final farStore = TestDataBuilders.createTestStore(
        id: 'far_store',
        name: '遠い中華料理店',
        lat: 43.0618,
        lng: 141.3545, // 札幌
      );

      await tester.pumpWidget(buildTestWidget(farStore));
      await tester.pump();

      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.text('マップアプリで開く'), findsOneWidget);
    });
  });
}
