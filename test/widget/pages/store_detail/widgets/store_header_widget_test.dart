import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/widgets/store_header_widget.dart';

void main() {
  group('StoreHeaderWidget Tests', () {
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

    testWidgets('should display store name and status', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreHeaderWidget(store: testStore),
          ),
        ),
      );

      // Assert
      expect(find.text('テスト中華料理店'), findsOneWidget);
      expect(find.text('行きたい'), findsOneWidget);
    });

    testWidgets('should display status icon correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreHeaderWidget(store: testStore),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should display different status correctly', (tester) async {
      // Arrange
      final visitedStore = testStore.copyWith(status: StoreStatus.visited);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreHeaderWidget(store: visitedStore),
          ),
        ),
      );

      // Assert
      expect(find.text('行った'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}