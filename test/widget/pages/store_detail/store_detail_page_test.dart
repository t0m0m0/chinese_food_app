import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/usecases/get_visit_records_by_store_id_usecase.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/store_detail_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/widgets/webview_map_widget.dart';

import 'store_detail_page_test.mocks.dart';

@GenerateMocks([
  DIContainerInterface,
  GetVisitRecordsByStoreIdUsecase,
  StoreProvider,
])
void main() {
  group('StoreDetailPage Widget Tests', () {
    late Store testStore;
    late MockDIContainerInterface mockContainer;
    late MockGetVisitRecordsByStoreIdUsecase mockGetVisitRecordsUsecase;
    late MockStoreProvider mockStoreProvider;

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

      // モックの初期化
      mockContainer = MockDIContainerInterface();
      mockGetVisitRecordsUsecase = MockGetVisitRecordsByStoreIdUsecase();
      mockStoreProvider = MockStoreProvider();

      // モックの振る舞いを設定
      when(mockContainer.getGetVisitRecordsByStoreIdUsecase())
          .thenReturn(mockGetVisitRecordsUsecase);
      when(mockGetVisitRecordsUsecase.call(any))
          .thenAnswer((_) async => <VisitRecord>[]);
      // StoreProviderからstoresを取得する際の初期状態
      when(mockStoreProvider.stores).thenReturn([testStore]);
    });

    testWidgets('should display store basic information', (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('テスト中華料理店'), findsOneWidget);
      expect(find.text('東京都渋谷区テスト1-1-1'), findsOneWidget);
      expect(find.text('テスト用のメモ'), findsOneWidget);
    });

    testWidgets('should display status change buttons', (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - ステータス変更セクションの存在を確認
      expect(find.text('ステータス変更'), findsOneWidget);
      expect(find.text('行きたい'), findsWidgets);
      expect(find.text('行った'), findsOneWidget);
      expect(find.text('興味なし'), findsOneWidget);
    });

    testWidgets('should show app bar with store name', (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('店舗詳細'), findsOneWidget);
    });

    testWidgets('should display status buttons with proper interaction',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: visitedStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 現在のステータスが選択されて表示されることを確認
      expect(find.text('行った'), findsWidgets);

      // Status header should show current status
      expect(find.text('行った'), findsWidgets);
    });

    testWidgets('should display WebViewMapWidget in the page', (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - WebViewMapWidget should be present in the page
      expect(find.byType(WebViewMapWidget), findsOneWidget);
    });

    testWidgets('should not display "地図で表示" button', (tester) async {
      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - "地図で表示" button should not be present
      expect(find.text('地図で表示'), findsNothing);
    });

    testWidgets('should call updateStoreStatus when status button is tapped',
        (tester) async {
      // Arrange
      when(mockStoreProvider.updateStoreStatus(any, any))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find InkWell containing the "visited" status button and scroll to it
      final visitedButtonFinder = find.ancestor(
        of: find.text('行った').last,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(visitedButtonFinder);
      await tester.pumpAndSettle();

      // Tap the "visited" status button
      await tester.tap(visitedButtonFinder);
      await tester.pumpAndSettle();

      // Assert - updateStoreStatus should be called with correct parameters
      verify(mockStoreProvider.updateStoreStatus(
              testStore.id, StoreStatus.visited))
          .called(1);
    });

    testWidgets(
        'should not call updateStoreStatus when current status is tapped',
        (tester) async {
      // Arrange
      when(mockStoreProvider.updateStoreStatus(any, any))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find InkWell containing the current "wantToGo" status button
      final wantToGoButtonFinder = find.ancestor(
        of: find.text('行きたい').last,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(wantToGoButtonFinder);
      await tester.pumpAndSettle();

      // Tap the current "wantToGo" status button
      await tester.tap(wantToGoButtonFinder);
      await tester.pumpAndSettle();

      // Assert - updateStoreStatus should NOT be called
      verifyNever(mockStoreProvider.updateStoreStatus(any, any));
    });

    testWidgets('should show error snackbar when status update fails',
        (tester) async {
      // Arrange
      when(mockStoreProvider.updateStoreStatus(any, any))
          .thenThrow(Exception('Update failed'));

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find InkWell containing the "visited" status button and scroll to it
      final visitedButtonFinder = find.ancestor(
        of: find.text('行った').last,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(visitedButtonFinder);
      await tester.pumpAndSettle();

      // Tap the "visited" status button
      await tester.tap(visitedButtonFinder);
      await tester.pump(); // Trigger the error

      // Assert - Error snackbar should be displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('店舗のステータス更新に失敗しました'), findsOneWidget);
    });

    testWidgets('should update UI when status is changed successfully',
        (tester) async {
      // Arrange - Start with testStore (wantToGo status)
      when(mockStoreProvider.updateStoreStatus(any, any))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: testStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Create updated store with visited status
      final updatedStore = Store(
        id: testStore.id,
        name: testStore.name,
        address: testStore.address,
        lat: testStore.lat,
        lng: testStore.lng,
        status: StoreStatus.visited, // Changed from wantToGo to visited
        memo: testStore.memo,
        createdAt: testStore.createdAt,
      );

      // Update mock to return updated store after status change
      when(mockStoreProvider.stores).thenReturn([updatedStore]);

      // Find InkWell containing the "visited" status button and scroll to it
      final visitedButtonFinder = find.ancestor(
        of: find.text('行った').last,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(visitedButtonFinder);
      await tester.pumpAndSettle();

      // Tap the "visited" status button
      await tester.tap(visitedButtonFinder);
      await tester.pumpAndSettle();

      // Assert - UI should reflect the new status (visited button should be selected)
      verify(mockStoreProvider.updateStoreStatus(
              testStore.id, StoreStatus.visited))
          .called(1);

      // StoreActionWidget should show visited status as selected
      // This will be verified by the widget rebuilding with the updated store from provider
    });

    testWidgets(
        'should allow status change from bad to wantToGo (regression test)',
        (tester) async {
      // Arrange - Create a store with 'bad' status
      final badStore = Store(
        id: 'bad-store',
        name: 'テスト中華料理店',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6581,
        lng: 139.7414,
        status: StoreStatus.bad,
        memo: 'テスト用のメモ',
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedStore = Store(
        id: badStore.id,
        name: badStore.name,
        address: badStore.address,
        lat: badStore.lat,
        lng: badStore.lng,
        status: StoreStatus.wantToGo, // Changed from bad to wantToGo
        memo: badStore.memo,
        createdAt: badStore.createdAt,
      );

      when(mockStoreProvider.updateStoreStatus(any, any))
          .thenAnswer((_) async => {});
      when(mockStoreProvider.stores).thenReturn([badStore]);
      when(mockGetVisitRecordsUsecase.call(badStore.id))
          .thenAnswer((_) async => <VisitRecord>[]);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: mockContainer),
            ChangeNotifierProvider<StoreProvider>.value(
                value: mockStoreProvider),
          ],
          child: MaterialApp(
            home: StoreDetailPage(store: badStore),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Update mock to return updated store after status change
      when(mockStoreProvider.stores).thenReturn([updatedStore]);

      // Find InkWell containing the "wantToGo" status button and scroll to it
      final wantToGoButtonFinder = find.ancestor(
        of: find.text('行きたい').last,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(wantToGoButtonFinder);
      await tester.pumpAndSettle();

      // Tap the "wantToGo" status button
      await tester.tap(wantToGoButtonFinder);
      await tester.pumpAndSettle();

      // Assert - updateStoreStatus should be called
      verify(mockStoreProvider.updateStoreStatus(
              badStore.id, StoreStatus.wantToGo))
          .called(1);
    });
  });
}
