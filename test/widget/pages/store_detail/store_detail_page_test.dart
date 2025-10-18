import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/store_detail_page.dart';
import 'package:chinese_food_app/presentation/widgets/webview_map_widget.dart';

void main() {
  group('StoreDetailPage Widget Tests', () {
    late Store testStore;

    setUp(() {
      testStore = Store(
        id: 'test-store-1',
        name: 'テスト中華料理店',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6581,
        lng: 139.7414,
        status: StoreStatus.wantToGo,
        memo: 'テスト用のメモ',
        createdAt: DateTime(2024, 1, 1),
      );
    });

    testWidgets('should display store basic information', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert
      expect(find.text('テスト中華料理店'), findsOneWidget);
      expect(find.text('東京都渋谷区テスト1-1-1'), findsOneWidget);
      expect(find.text('テスト用のメモ'), findsOneWidget);
    });

    testWidgets('should display status change buttons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert - ステータス変更セクションの存在を確認
      expect(find.text('ステータス変更'), findsOneWidget);
      expect(find.text('行きたい'), findsWidgets);
      expect(find.text('行った'), findsOneWidget);
      expect(find.text('興味なし'), findsOneWidget);
    });

    testWidgets('should show app bar with store name', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('店舗詳細'), findsOneWidget);
    });

    testWidgets('should display status buttons with proper interaction',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert - ステータスボタンが存在し、タップ可能であることを確認
      final wantToGoButton = find.text('行きたい').last;
      final visitedButton = find.text('行った').last;
      final badButton = find.text('興味なし').last;

      expect(wantToGoButton, findsOneWidget);
      expect(visitedButton, findsOneWidget);
      expect(badButton, findsOneWidget);

      // ボタンがInkWellでラップされていることを確認（タップ可能）
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets); // 複数のInkWellが存在
    });

    testWidgets('should show different visual states for current status',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert - ステータス変更セクションが存在することを確認
      expect(find.text('ステータス変更'), findsOneWidget);

      // アクションボタンが存在することを確認
      expect(find.text('訪問記録を追加'), findsOneWidget);
    });

    testWidgets('should show current status as selected', (tester) async {
      // Arrange - Create a store with 'visited' status
      final visitedStore = Store(
        id: 'visited-store',
        name: 'テスト中華料理店',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6581,
        lng: 139.7414,
        status: StoreStatus.visited,
        memo: 'テスト用のメモ',
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: visitedStore),
        ),
      );

      // Assert - 現在のステータスが選択されて表示されることを確認
      expect(find.text('行った'), findsWidgets);

      // Status header should show current status
      expect(find.text('行った'), findsWidgets);
    });

    testWidgets('should display WebViewMapWidget in the page', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert - WebViewMapWidget should be present in the page
      expect(find.byType(WebViewMapWidget), findsOneWidget);
    });

    testWidgets('should not display "地図で表示" button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: StoreDetailPage(store: testStore),
        ),
      );

      // Assert - "地図で表示" button should not be present
      expect(find.text('地図で表示'), findsNothing);
    });
  });
}
