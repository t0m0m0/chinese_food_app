import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';

void main() {
  late StoreProvider provider;
  late MockStoreRepository mockRepository;

  setUp(() {
    mockRepository = MockStoreRepository();
    provider = StoreProvider(repository: mockRepository);
  });

  group('N+1 Query Performance Tests - Issue #84', () {
    test('should minimize database queries when checking duplicates', () async {
      // TDD: Red - 重複チェック時のクエリ最適化テスト

      // 大量の既存店舗データを準備（1000件）
      final existingStores = List.generate(
          1000,
          (index) => Store(
                id: 'existing_$index',
                name: '既存店舗_$index',
                address: '東京都_$index',
                lat: 35.6580339 + (index * 0.001),
                lng: 139.7016358 + (index * 0.001),
                status: StoreStatus.wantToGo,
                createdAt: DateTime.now(),
              ));

      // API検索結果として100件の新しい店舗を準備
      final apiStores = List.generate(
          100,
          (index) => Store(
                id: 'api_store_$index',
                name: 'API店舗_$index',
                address: '神奈川県_$index',
                lat: 35.4580339 + (index * 0.001),
                lng: 139.6016358 + (index * 0.001),
                status: null, // 新しい店舗はステータス未設定
                createdAt: DateTime.now(),
              ));

      // モックの設定
      mockRepository.stubGetAllStores(existingStores);
      mockRepository.stubSearchStoresFromApi(apiStores);

      // プロバイダーに既存データをロード
      await provider.loadStores();

      // パフォーマンス測定開始
      final stopwatch = Stopwatch()..start();

      // API検索実行（内部で重複チェックが行われる）
      await provider.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        count: 100,
      );

      stopwatch.stop();

      // パフォーマンス検証
      // 1000 x 100 = 100,000回の個別クエリでは非現実的に時間がかかるはず
      // 最適化されていれば2秒以内で完了するはず
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Duplicate check should be optimized to avoid N+1 queries');

      // 機能的な正確性も検証
      expect(provider.stores.length, equals(1100), // 1000 + 100
          reason: 'All new stores should be added without duplicates');
    });

    test('should use efficient status filtering without N+1 queries', () async {
      // TDD: Red - ステータス別フィルタリングの効率化テスト

      // 大量の店舗データを準備（異なるステータス）
      final stores = <Store>[];
      for (int i = 0; i < 1000; i++) {
        final status = [
          StoreStatus.wantToGo,
          StoreStatus.visited,
          StoreStatus.bad,
        ][i % 3];

        stores.add(Store(
          id: 'store_$i',
          name: '店舗_$i',
          address: '住所_$i',
          lat: 35.6580339,
          lng: 139.7016358,
          status: status,
          createdAt: DateTime.now(),
        ));
      }

      // モックの設定
      mockRepository.stubGetAllStores(stores);

      // プロバイダーにデータを設定
      await provider.loadStores();

      // パフォーマンス測定
      final stopwatch = Stopwatch()..start();

      // 複数回のステータス別取得を実行
      for (int i = 0; i < 10; i++) {
        final wantToGo = provider.wantToGoStores;
        final visited = provider.visitedStores;
        final bad = provider.badStores;

        // 結果の検証
        expect(wantToGo.length, greaterThan(300));
        expect(visited.length, greaterThan(300));
        expect(bad.length, greaterThan(300));
      }

      stopwatch.stop();

      // キャッシュにより2回目以降は高速化されるはず
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Status filtering should be cached for performance');
    });
  });
}

// テスト用モックリポジトリ
class MockStoreRepository implements StoreRepository {
  List<Store>? _stubGetAllStoresResult;
  List<Store>? _stubSearchStoresFromApiResult;

  void stubGetAllStores(List<Store> stores) {
    _stubGetAllStoresResult = stores;
  }

  void stubSearchStoresFromApi(List<Store> stores) {
    _stubSearchStoresFromApiResult = stores;
  }

  @override
  Future<List<Store>> getAllStores() async {
    return _stubGetAllStoresResult ?? [];
  }

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int count = 20,
    int range = 3,
    int start = 1,
  }) async {
    return _stubSearchStoresFromApiResult ?? [];
  }

  @override
  Future<void> insertStore(Store store) async {}

  @override
  Future<void> updateStore(Store store) async {}

  @override
  Future<void> deleteStore(String storeId) async {}

  @override
  Future<Store?> getStoreById(String storeId) async => null;

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async => [];

  @override
  Future<List<Store>> searchStores(String query) async => [];
}
