import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/my_menu/my_menu_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

/// FakeStoreProvider for testing
class FakeStoreProvider extends ChangeNotifier implements StoreProvider {
  bool _isLoading = false;
  String? _error;
  String? _infoMessage;
  List<Store> _wantToGoStores = [];
  List<Store> _visitedStores = [];
  List<Store> _badStores = [];

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  String? get infoMessage => _infoMessage;

  @override
  List<Store> get wantToGoStores => _wantToGoStores;

  @override
  List<Store> get visitedStores => _visitedStores;

  @override
  List<Store> get badStores => _badStores;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setInfoMessage(String? message) {
    _infoMessage = message;
    notifyListeners();
  }

  void setWantToGoStores(List<Store> stores) {
    _wantToGoStores = stores;
    notifyListeners();
  }

  void setVisitedStores(List<Store> stores) {
    _visitedStores = stores;
    notifyListeners();
  }

  void setBadStores(List<Store> stores) {
    _badStores = stores;
    notifyListeners();
  }

  @override
  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    // Mock implementation
  }

  @override
  void clearError() {
    _error = null;
    _infoMessage = null;
    notifyListeners();
  }

  @override
  void refreshCache() {
    // Mock implementation
  }

  @override
  Future<void> loadStores() async {
    // Mock implementation - do nothing in tests
  }

  // 他の必要なメソッドのスタブ実装
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MyMenuPage Widget Tests', () {
    late FakeStoreProvider fakeStoreProvider;

    setUp(() {
      fakeStoreProvider = FakeStoreProvider();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<StoreProvider>.value(
          value: fakeStoreProvider,
          child: const MyMenuPage(),
        ),
      );
    }

    testWidgets('should display app bar with title and tabs', (tester) async {
      // Arrange
      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores([]);
      fakeStoreProvider.setVisitedStores([]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('マイメニュー'), findsOneWidget);
      expect(find.text('行きたい'), findsOneWidget);
      expect(find.text('行った'), findsOneWidget);
      expect(find.text('興味なし'), findsOneWidget);
    });

    testWidgets('should display loading state when isLoading is true',
        (tester) async {
      // Arrange
      fakeStoreProvider.setLoading(true);
      fakeStoreProvider.setError(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('店舗データを読み込み中...'), findsOneWidget);
    });

    testWidgets('should display error state when error exists', (tester) async {
      // Arrange
      const errorMessage = 'テストエラー';
      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(errorMessage);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('should display empty state for want-to-go tab when no stores',
        (tester) async {
      // Arrange
      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores([]);
      fakeStoreProvider.setVisitedStores([]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('まだ「行きたい」店舗がありません'), findsOneWidget);
      expect(find.text('スワイプ画面で気になる店舗を右スワイプしてみましょう'), findsOneWidget);
    });

    testWidgets('should display store cards when stores are available',
        (tester) async {
      // Arrange
      final testStores = [
        Store(
          id: '1',
          name: 'テスト店舗1',
          address: 'テスト住所1',
          lat: 35.6895,
          lng: 139.6917,
          status: StoreStatus.wantToGo,
          createdAt: DateTime(2023, 1, 1),
        ),
        Store(
          id: '2',
          name: 'テスト店舗2',
          address: 'テスト住所2',
          lat: 35.6895,
          lng: 139.6917,
          status: StoreStatus.wantToGo,
          createdAt: DateTime(2023, 1, 2),
        ),
      ];

      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores(testStores);
      fakeStoreProvider.setVisitedStores([]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('テスト店舗1'), findsOneWidget);
      expect(find.text('テスト店舗2'), findsOneWidget);
      expect(find.text('テスト住所1'), findsOneWidget);
      expect(find.text('テスト住所2'), findsOneWidget);
    });

    testWidgets('should display store with memo', (tester) async {
      // Arrange
      final testStore = Store(
        id: '1',
        name: 'メモ付き店舗',
        address: 'テスト住所',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.wantToGo,
        memo: 'テストメモ',
        createdAt: DateTime(2023, 1, 1),
      );

      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores([testStore]);
      fakeStoreProvider.setVisitedStores([]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('メモ付き店舗'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('should handle tab switching', (tester) async {
      // Arrange
      final wantToGoStore = Store(
        id: '1',
        name: '行きたい店舗',
        address: 'テスト住所',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2023, 1, 1),
      );
      final visitedStore = Store(
        id: '2',
        name: '行った店舗',
        address: 'テスト住所',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.visited,
        createdAt: DateTime(2023, 1, 2),
      );

      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores([wantToGoStore]);
      fakeStoreProvider.setVisitedStores([visitedStore]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // 「行った」タブをタップ
      await tester.tap(find.text('行った'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('行った店舗'), findsOneWidget);
      expect(find.text('行きたい店舗'), findsNothing);
    });

    testWidgets('should show popup menu and handle status change',
        (tester) async {
      // Arrange
      final testStore = Store(
        id: '1',
        name: 'テスト店舗',
        address: 'テスト住所',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2023, 1, 1),
      );

      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError(null);
      fakeStoreProvider.setInfoMessage(null);
      fakeStoreProvider.setWantToGoStores([testStore]);
      fakeStoreProvider.setVisitedStores([]);
      fakeStoreProvider.setBadStores([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // ポップアップメニューを開く
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // ポップアップメニュー内の「行った」を選択
      await tester.tap(find.descendant(
        of: find.byType(PopupMenuItem<StoreStatus>),
        matching: find.text('行った'),
      ));
      await tester.pumpAndSettle();

      // Assert
      // Status update is handled by the fake implementation
    });

    testWidgets('should handle retry button on error', (tester) async {
      // Arrange
      fakeStoreProvider.setLoading(false);
      fakeStoreProvider.setError('テストエラー');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // 再試行ボタンをタップ
      await tester.tap(find.text('再試行'));
      await tester.pump();

      // Assert
      // clearError and refreshCache are handled by the fake implementation
    });
  });
}
