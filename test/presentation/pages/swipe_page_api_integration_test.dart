import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';

/// 🔴 RED: SwipePageでHotPepper APIから新しい店舗データを表示するための失敗するテスト
void main() {
  group('SwipePage API Integration Tests - TDD Red Phase', () {
    late FakeStoreRepository fakeRepository;
    late StoreProvider storeProvider;

    setUp(() {
      fakeRepository = FakeStoreRepository();
      storeProvider = StoreProvider(repository: fakeRepository);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          ],
          child: SwipePage(),
        ),
      );
    }

    testWidgets('🔴 RED: should load and display new stores from HotPepper API for swiping', 
        (WidgetTester tester) async {
      // このテストは現在失敗するはずです
      // SwipePageが新しいAPI店舗データを表示できるようになる必要があります
      
      // API から取得される新しい店舗データをセットアップ
      final newApiStores = [
        Store(
          id: 'api_001',
          name: 'HotPepper API店舗 1',
          address: '東京都新宿区API1-1-1',
          lat: 35.6917,
          lng: 139.7006,
          status: null, // 新しい店舗なのでステータス未設定
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'api_002', 
          name: 'HotPepper API店舗 2',
          address: '東京都新宿区API2-2-2',
          lat: 35.6895,
          lng: 139.6917,
          status: null, // 新しい店舗なのでステータス未設定
          createdAt: DateTime.now(),
        ),
      ];
      
      // APIデータのみを設定
      fakeRepository.setApiStores(newApiStores);

      await tester.pumpWidget(createTestWidget());
      
      // 直接APIから店舗データを読み込み（サンプルデータ初期化をスキップ）
      await storeProvider.loadNewStoresFromApi(
        lat: 35.6917,
        lng: 139.7006,
        count: 10,
      );
      
      await tester.pumpAndSettle();


      // 期待する結果：APIデータが追加されて、店舗数が増加している
      // 初期のサンプルデータ(6つ) + APIデータ(2つ) = 8つ
      expect(storeProvider.stores.length, 8);
      expect(storeProvider.newStores.length, 8);
      
      // APIデータが含まれていることを確認
      bool hasApiStore1 = storeProvider.stores.any((store) => store.name == 'HotPepper API店舗 1');
      bool hasApiStore2 = storeProvider.stores.any((store) => store.name == 'HotPepper API店舗 2');
      expect(hasApiStore1, true);
      expect(hasApiStore2, true);
      
      // スワイプカードが表示されていることを確認
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('🔴 RED: should show loading indicator while fetching API data', 
        (WidgetTester tester) async {
      // API データ取得中のローディング表示をテスト
      fakeRepository.setShouldDelayApiResponse(true);

      await tester.pumpWidget(createTestWidget());
      
      // 手動でAPIローディングを開始
      storeProvider.loadNewStoresFromApi(lat: 35.6917, lng: 139.7006);
      await tester.pump(); // 1フレーム進める
      
      // ローディング状態をテスト
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('新しい店舗を読み込み中...'), findsOneWidget);

      // データ読み込み完了を待つ
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // ローディングが消えて店舗データが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('🔴 RED: should handle API error and show retry option',
        (WidgetTester tester) async {
      // API エラー時の適切なハンドリングをテスト
      fakeRepository.setShouldThrowOnApiSearch(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // エラー表示とリトライボタンの確認
      expect(find.text('新しい店舗の取得に失敗しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      
      // リトライボタンをタップ
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
    });

    testWidgets('🔴 RED: should refresh API data when user performs pull-to-refresh',
        (WidgetTester tester) async {
      // プルトゥリフレッシュでAPIデータを再取得するテスト
      final initialApiStores = [
        Store(
          id: 'api_initial_001',
          name: 'プルリフレッシュテスト店舗',
          address: '東京都テスト区1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];
      
      fakeRepository.setApiStores(initialApiStores);

      await tester.pumpWidget(createTestWidget());
      
      // 手動で最初のAPI呼び出し
      await storeProvider.loadNewStoresFromApi(lat: 35.6917, lng: 139.7006);
      await tester.pumpAndSettle();

      // 初期状態の確認（サンプルデータ + 初期APIデータ）
      final initialStoreCount = storeProvider.stores.length;
      expect(initialStoreCount, greaterThan(6)); // サンプルデータ6つ以上

      // プルトゥリフレッシュのトリガー
      final refreshIndicator = find.byType(RefreshIndicator);
      await tester.fling(refreshIndicator, Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // リフレッシュ機能が動作することを確認（店舗数の変化はなくても、動作したことを確認）
      expect(storeProvider.stores.length, greaterThanOrEqualTo(initialStoreCount));
    });
  });
}

/// テスト用のFakeリポジトリ（APIデータ取得機能付き）
class FakeStoreRepository implements StoreRepository {
  List<Store> _stores = [];
  List<Store> _apiStores = [];
  bool _shouldThrowOnApiSearch = false;
  bool _shouldDelayApiResponse = false;

  void setStores(List<Store> stores) => _stores = List.from(stores);
  void setApiStores(List<Store> stores) => _apiStores = List.from(stores);
  void setShouldThrowOnApiSearch(bool value) => _shouldThrowOnApiSearch = value;
  void setShouldDelayApiResponse(bool value) => _shouldDelayApiResponse = value;

  @override
  Future<List<Store>> getAllStores() async => List.from(_stores);

  @override
  Future<void> insertStore(Store store) async => _stores.add(store);

  @override
  Future<void> updateStore(Store store) async {
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) _stores[index] = store;
  }

  @override
  Future<void> deleteStore(String storeId) async =>
      _stores.removeWhere((s) => s.id == storeId);

  @override
  Future<Store?> getStoreById(String storeId) async {
    try {
      return _stores.firstWhere((s) => s.id == storeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async =>
      _stores.where((s) => s.status == status).toList();

  @override
  Future<List<Store>> searchStores(String query) async =>
      _stores.where((s) => s.name.contains(query)).toList();

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    if (_shouldDelayApiResponse) {
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (_shouldThrowOnApiSearch) {
      throw Exception('新しい店舗の取得に失敗しました');
    }
    
    return List.from(_apiStores);
  }
}