import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';
import 'package:chinese_food_app/presentation/pages/visit_record/visit_record_form_page.dart';

import 'visit_record_form_page_test.mocks.dart';

@GenerateMocks([AddVisitRecordUsecase])
void main() {
  late MockAddVisitRecordUsecase mockAddVisitRecordUsecase;
  late Store testStore;

  setUp(() {
    mockAddVisitRecordUsecase = MockAddVisitRecordUsecase();
    testStore = Store(
      id: 'test-store-id',
      name: 'テスト中華料理店',
      address: '東京都渋谷区テスト町1-1-1',
      lat: 35.6580339,
      lng: 139.7016358,
      status: StoreStatus.wantToGo,
      memo: 'テスト用の店舗',
      createdAt: DateTime(2024, 1, 15),
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Provider<AddVisitRecordUsecase>.value(
          value: mockAddVisitRecordUsecase,
          child: VisitRecordFormPage(store: testStore),
        ),
      ),
    );
  }

  group('VisitRecordFormPage Widget Tests', () {
    testWidgets('should display store information',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('テスト中華料理店'), findsOneWidget);
      expect(find.text('東京都渋谷区テスト町1-1-1'), findsOneWidget);
    });

    testWidgets('should display form fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byKey(const Key('visit_date_field')), findsOneWidget);
      expect(find.byKey(const Key('menu_field')), findsOneWidget);
      expect(find.byKey(const Key('memo_field')), findsOneWidget);
      expect(find.byKey(const Key('save_button')), findsOneWidget);
    });

    testWidgets('should display validation errors for empty required fields',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Assert
      expect(find.text('メニューを入力してください'), findsOneWidget);
    });

    testWidgets('should call AddVisitRecordUsecase when form is valid',
        (WidgetTester tester) async {
      // Arrange
      final expectedVisitRecord = VisitRecord(
        id: 'new-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2024, 1, 20, 12, 30),
        menu: 'チャーハン',
        memo: '美味しかった',
        createdAt: DateTime(2024, 1, 20, 20, 0),
      );

      when(mockAddVisitRecordUsecase.call(
        storeId: anyNamed('storeId'),
        visitedAt: anyNamed('visitedAt'),
        menu: anyNamed('menu'),
        memo: anyNamed('memo'),
      )).thenAnswer((_) async => expectedVisitRecord);

      await tester.pumpWidget(createTestWidget());

      // Act - fill form
      await tester.enterText(find.byKey(const Key('menu_field')), 'チャーハン');
      await tester.enterText(find.byKey(const Key('memo_field')), '美味しかった');

      // Act - submit form
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Assert
      verify(mockAddVisitRecordUsecase.call(
        storeId: 'test-store-id',
        visitedAt: anyNamed('visitedAt'),
        menu: 'チャーハン',
        memo: '美味しかった',
      )).called(1);
    });

    testWidgets('should call usecase successfully when form is valid',
        (WidgetTester tester) async {
      // Arrange
      final expectedVisitRecord = VisitRecord(
        id: 'new-visit-id',
        storeId: 'test-store-id',
        visitedAt: DateTime(2024, 1, 20, 12, 30),
        menu: 'チャーハン',
        memo: '美味しかった',
        createdAt: DateTime(2024, 1, 20, 20, 0),
      );

      when(mockAddVisitRecordUsecase.call(
        storeId: anyNamed('storeId'),
        visitedAt: anyNamed('visitedAt'),
        menu: anyNamed('menu'),
        memo: anyNamed('memo'),
      )).thenAnswer((_) async => expectedVisitRecord);

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('menu_field')), 'チャーハン');
      await tester.enterText(find.byKey(const Key('memo_field')), '美味しかった');
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Assert - verify the usecase was called correctly
      verify(mockAddVisitRecordUsecase.call(
        storeId: 'test-store-id',
        visitedAt: anyNamed('visitedAt'),
        menu: 'チャーハン',
        memo: '美味しかった',
      )).called(1);
    });

    testWidgets('should handle error when save fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockAddVisitRecordUsecase.call(
        storeId: anyNamed('storeId'),
        visitedAt: anyNamed('visitedAt'),
        menu: anyNamed('menu'),
        memo: anyNamed('memo'),
      )).thenThrow(Exception('Save failed'));

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('menu_field')), 'チャーハン');
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Assert - verify the usecase was still called
      verify(mockAddVisitRecordUsecase.call(
        storeId: anyNamed('storeId'),
        visitedAt: anyNamed('visitedAt'),
        menu: anyNamed('menu'),
        memo: anyNamed('memo'),
      )).called(1);
    });
  });
}
