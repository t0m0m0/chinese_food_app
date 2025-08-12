import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/store_map_widget.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('StoreMapWidget', () {
    late Store validStore;
    late Store edgeCaseStore;

    setUp(() {
      validStore = Store(
        id: 'test_store_1',
        name: 'テスト中華料理店',
        address: '東京都渋谷区1-2-3',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: null,
        createdAt: DateTime.now(),
      );

      // 境界値でテスト（GoogleMapsAPIキー無効時のケースをテスト）
      edgeCaseStore = Store(
        id: 'test_store_2',
        name: 'エッジケース店舗',
        address: '境界値テスト場所',
        lat: 90.0,  // 有効な緯度の境界値
        lng: 180.0, // 有効な経度の境界値
        status: StoreStatus.wantToGo,
        memo: null,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('should display error UI when GoogleMaps is unavailable', (WidgetTester tester) async {
      // MockGoogleMapsが利用できない環境をシミュレート
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StoreMapWidget(store: validStore),
        ),
      ));

      // 初期のローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 時間を進めてエラー状態に遷移させる
      await tester.pump(const Duration(seconds: 2));

      // エラーアイコンが表示されることを確認
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // エラーメッセージが表示されることを確認
      expect(find.text('地図を表示できません'), findsOneWidget);
      
      // 外部地図アプリボタンが表示されることを確認
      expect(find.text('外部地図アプリで開く'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StoreMapWidget(store: validStore),
        ),
      ));

      // 初期状態でローディングインジケーターが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display external map button when error occurs', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StoreMapWidget(store: edgeCaseStore),
        ),
      ));

      // ローディング状態をスキップしてエラー状態に遷移
      await tester.pump(const Duration(seconds: 2));

      // 外部地図アプリボタンを見つける
      final externalMapButton = find.text('外部地図アプリで開く');
      expect(externalMapButton, findsOneWidget);

      // ボタンタップのテスト（実際の起動はしない）
      await tester.tap(externalMapButton);
      await tester.pump();

      // エラーが発生せずボタンが機能することを確認
      expect(externalMapButton, findsOneWidget);
    });
  });
}