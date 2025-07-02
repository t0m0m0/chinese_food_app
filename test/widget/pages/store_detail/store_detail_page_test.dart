import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/store_detail_page.dart';

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
  });
}