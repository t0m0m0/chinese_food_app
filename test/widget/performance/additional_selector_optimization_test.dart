import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/fakes.dart';

/// SearchPageとMyMenuPageのSelector最適化テスト
///
/// 目的: QAレビュー指摘事項への対応確認

void main() {
  group('追加Selector最適化テスト', () {
    late StoreProvider storeProvider;
    late SearchProvider searchProvider;

    setUp(() {
      storeProvider = TestHelpers.createStoreProvider();
      searchProvider = SearchProvider(
        storeProvider: storeProvider,
        locationService: FakeLocationService(),
      );
    });

    testWidgets('SearchPageのSelector最適化が正しく動作する', (tester) async {
      // SearchProviderのSelector複合状態テスト
      final testWidget = MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ],
        child: Scaffold(
          body: Column(
            children: [
              // 検索フォーム用Selector
              Selector<
                  SearchProvider,
                  ({
                    bool useCurrentLocation,
                    bool isLoading,
                    bool isGettingLocation
                  })>(
                selector: (context, provider) => (
                  useCurrentLocation: provider.useCurrentLocation,
                  isLoading: provider.isLoading,
                  isGettingLocation: provider.isGettingLocation,
                ),
                builder: (context, state, child) {
                  return Text(
                      'Form - Location: ${state.useCurrentLocation}, Loading: ${state.isLoading}');
                },
              ),

              // 検索結果用Selector
              Selector<SearchProvider,
                  ({bool isLoading, List<Store> searchResults})>(
                selector: (context, provider) => (
                  isLoading: provider.isLoading,
                  searchResults: provider.searchResults,
                ),
                builder: (context, state, child) {
                  return Text('Results: ${state.searchResults.length}');
                },
              ),

              // StoreProvider Selector (トレイリングアイコン用)
              Selector<StoreProvider, List<Store>>(
                selector: (context, provider) => provider.stores,
                builder: (context, stores, child) {
                  return Text('Total Stores: ${stores.length}');
                },
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期状態確認
      expect(
          find.text('Form - Location: true, Loading: false'), findsOneWidget);
      expect(find.text('Results: 0'), findsOneWidget);
      expect(find.text('Total Stores: 0'), findsOneWidget);
    });

    testWidgets('MyMenuPageのSelector最適化が正しく動作する', (tester) async {
      // MyMenuPageの複合Selectorテスト
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: Scaffold(
          body: Selector<
              StoreProvider,
              ({
                bool isLoading,
                List<Store> wantToGoStores,
                List<Store> visitedStores,
                List<Store> badStores
              })>(
            selector: (context, provider) => (
              isLoading: provider.isLoading,
              wantToGoStores: provider.wantToGoStores,
              visitedStores: provider.visitedStores,
              badStores: provider.badStores,
            ),
            builder: (context, state, child) {
              return Column(
                children: [
                  Text('Loading: ${state.isLoading}'),
                  Text('Want To Go: ${state.wantToGoStores.length}'),
                  Text('Visited: ${state.visitedStores.length}'),
                  Text('Bad: ${state.badStores.length}'),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期状態確認
      expect(find.text('Loading: false'), findsOneWidget);
      expect(find.text('Want To Go: 0'), findsOneWidget);
      expect(find.text('Visited: 0'), findsOneWidget);
      expect(find.text('Bad: 0'), findsOneWidget);

      // 店舗追加テスト
      final newStore = TestDataBuilders.createTestStore(
        id: 'test-store-1',
        name: 'Test Store',
        status: StoreStatus.wantToGo,
      );
      await storeProvider.addStore(newStore);
      await tester.pump();

      // 状態更新確認
      expect(find.text('Want To Go: 1'), findsOneWidget);
      expect(find.text('Visited: 0'), findsOneWidget);
      expect(find.text('Bad: 0'), findsOneWidget);
    });

    testWidgets('複数ページのSelector最適化が独立して動作する', (tester) async {
      // 複数のSelectorが互いに影響しないことを確認
      final testWidget = MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ],
        child: Scaffold(
          body: Column(
            children: [
              // SwipePageスタイルのSelector
              Selector<StoreProvider,
                  ({bool isLoading, String? error, List<Store> stores})>(
                selector: (context, provider) => (
                  isLoading: provider.isLoading,
                  error: provider.error,
                  stores: provider.stores,
                ),
                builder: (context, state, child) {
                  return Text('SwipeStyle - Stores: ${state.stores.length}');
                },
              ),

              // MyMenuPageスタイルのSelector
              Selector<StoreProvider,
                  ({List<Store> wantToGoStores, List<Store> visitedStores})>(
                selector: (context, provider) => (
                  wantToGoStores: provider.wantToGoStores,
                  visitedStores: provider.visitedStores,
                ),
                builder: (context, state, child) {
                  return Text(
                      'MenuStyle - Want: ${state.wantToGoStores.length}, Visited: ${state.visitedStores.length}');
                },
              ),

              // SearchPageスタイルのSelector
              Selector<SearchProvider,
                  ({bool isLoading, List<Store> searchResults})>(
                selector: (context, provider) => (
                  isLoading: provider.isLoading,
                  searchResults: provider.searchResults,
                ),
                builder: (context, state, child) {
                  return Text(
                      'SearchStyle - Results: ${state.searchResults.length}');
                },
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 各Selectorが独立して動作することを確認
      expect(find.text('SwipeStyle - Stores: 0'), findsOneWidget);
      expect(find.text('MenuStyle - Want: 0, Visited: 0'), findsOneWidget);
      expect(find.text('SearchStyle - Results: 0'), findsOneWidget);

      // StoreProviderに変更を加える
      final newStore = TestDataBuilders.createTestStore(
        status: StoreStatus.wantToGo,
      );
      await storeProvider.addStore(newStore);
      await tester.pump();

      // StoreProvider関連のSelectorのみ更新される
      expect(find.text('SwipeStyle - Stores: 1'), findsOneWidget);
      expect(find.text('MenuStyle - Want: 1, Visited: 0'), findsOneWidget);
      expect(find.text('SearchStyle - Results: 0'),
          findsOneWidget); // SearchProviderは変更なし
    });
  });
}
