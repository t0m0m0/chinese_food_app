import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/widgets/store_info_widget.dart';

void main() {
  group('StoreInfoWidget Tests', () {
    late Store testStore;
    late Store testStoreWithMemo;

    setUp(() {
      testStore = Store(
        id: 'test-store-1',
        name: 'テスト中華料理店',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6581,
        lng: 139.7414,
        status: StoreStatus.wantToGo,
        memo: null,
        createdAt: DateTime(2024, 1, 1),
      );

      testStoreWithMemo = testStore.copyWith(memo: '美味しい麻婆豆腐がおすすめ');
    });

    testWidgets('should display store address and created date', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreInfoWidget(store: testStore),
          ),
        ),
      );

      // Assert
      expect(find.text('基本情報'), findsOneWidget);
      expect(find.text('東京都渋谷区テスト1-1-1'), findsOneWidget);
      expect(find.text('2024/01/01'), findsOneWidget);
      expect(find.text('住所'), findsOneWidget);
      expect(find.text('登録日'), findsOneWidget);
    });

    testWidgets('should display memo when provided', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreInfoWidget(store: testStoreWithMemo),
          ),
        ),
      );

      // Assert
      expect(find.text('メモ'), findsOneWidget);
      expect(find.text('美味しい麻婆豆腐がおすすめ'), findsOneWidget);
    });

    testWidgets('should not display memo section when memo is null', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreInfoWidget(store: testStore),
          ),
        ),
      );

      // Assert
      expect(find.text('メモ'), findsNothing);
    });

    testWidgets('should display appropriate icons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreInfoWidget(store: testStore),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}