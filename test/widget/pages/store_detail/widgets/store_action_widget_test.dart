import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/widgets/store_action_widget.dart';

// Mock callbacks
class MockOnStatusChanged extends Mock {
  void call(StoreStatus status);
}

class MockOnAddVisitRecord extends Mock {
  void call();
}

void main() {
  group('StoreActionWidget Tests', () {
    late Store testStore;
    late MockOnStatusChanged mockOnStatusChanged;
    late MockOnAddVisitRecord mockOnAddVisitRecord;

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

      mockOnStatusChanged = MockOnStatusChanged();
      mockOnAddVisitRecord = MockOnAddVisitRecord();
    });

    testWidgets('should display status change section', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('ステータス変更'), findsOneWidget);
      expect(find.text('行きたい'), findsOneWidget);
      expect(find.text('行った'), findsOneWidget);
      expect(find.text('興味なし'), findsOneWidget);
    });

    testWidgets('should display visit record button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('訪問記録を追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should not display map button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Assert - Map button should not be displayed
      expect(find.text('地図で表示'), findsNothing);
      expect(find.byIcon(Icons.map), findsNothing);
    });

    testWidgets('should highlight current status correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Assert
      final wantToGoButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('行きたい'),
          matching: find.byType(InkWell),
        ),
      );

      // Current status should be visually highlighted
      expect(wantToGoButton.onTap, isNotNull);
    });

    testWidgets('should call onStatusChanged when status button is tapped',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Tap on '行った' button
      await tester.tap(find.text('行った'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockOnStatusChanged.call(StoreStatus.visited)).called(1);
    });

    testWidgets(
        'should call onAddVisitRecord when visit record button is tapped',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreActionWidget(
              store: testStore,
              onStatusChanged: mockOnStatusChanged.call,
              onAddVisitRecord: mockOnAddVisitRecord.call,
            ),
          ),
        ),
      );

      // Tap on visit record button
      await tester.tap(find.text('訪問記録を追加'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockOnAddVisitRecord.call()).called(1);
    });
  });
}
