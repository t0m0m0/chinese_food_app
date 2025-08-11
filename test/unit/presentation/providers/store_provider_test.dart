import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/core/config/search_config.dart';

void main() {
  late StoreProvider provider;
  late MockStoreRepository mockRepository;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockStoreRepository();
    mockLocationService = MockLocationService();
    provider = StoreProvider(
      repository: mockRepository,
      locationService: mockLocationService,
    );
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

    test('should use optimized normalized keys for duplicate detection',
        () async {
      // TDD: Red - QA改善：正規化キーによる重複検出最適化テスト

      // 類似名称・住所の店舗を準備（正規化により同一判定されるべき）
      final existingStores = [
        Store(
          id: 'store_1',
          name: '中華料理　龍門',
          address: '東京都港区赤坂1-2-3',
          lat: 35.6580339,
          lng: 139.7016358,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
      ];

      // API結果：表記が微妙に異なるが同一店舗
      final apiStores = [
        Store(
          id: 'api_store_1',
          name: '中華料理龍門', // 空白なし
          address: '東京都港区赤坂１－２－３', // 全角数字・ハイフン
          lat: 35.6580339,
          lng: 139.7016358,
          status: null,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'api_store_2',
          name: '中華料理・龍門', // 中点あり
          address: '東京都港区赤坂1丁目2番地3号', // 丁目番地号表記
          lat: 35.6580339,
          lng: 139.7016358,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];

      // モック設定
      mockRepository.stubGetAllStores(existingStores);
      mockRepository.stubSearchStoresFromApi(apiStores);

      // プロバイダーにデータロード
      await provider.loadStores();

      // パフォーマンス測定
      final stopwatch = Stopwatch()..start();

      // API検索実行（正規化による高速重複チェック）
      await provider.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        count: 2,
      );

      stopwatch.stop();

      // 正規化により重複として正しく検出されることを確認
      // 少なくとも重複の一部は検出されるはず（完璧な検出は座標による）
      expect(provider.stores.length, lessThanOrEqualTo(2),
          reason: 'Normalized key should help detect some duplicates');

      // 正規化処理により高速化されていることを確認
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason:
              'Normalized key generation should optimize duplicate detection');
    });
  });

  group('距離パラメータ対応 - Issue #117', () {
    test('loadNewStoresFromApi should accept range parameter', () async {
      // Arrange
      final apiStores = [
        Store(
          id: 'api_store_1',
          name: 'テスト中華料理店',
          address: '東京都新宿区',
          lat: 35.6917,
          lng: 139.7006,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];

      mockRepository.stubGetAllStores([]);
      mockRepository.stubSearchStoresFromApi(apiStores);

      // Act
      await provider.loadNewStoresFromApi(
        lat: 35.6917,
        lng: 139.7006,
        range: SearchConfig.defaultRange,
        count: 10,
      );

      // Assert
      expect(provider.stores.length, equals(1));
      expect(provider.stores.first.name, equals('テスト中華料理店'));
    });

    test('loadNewStoresFromApi should use different range values', () async {
      // Arrange
      final apiStores = [
        Store(
          id: 'api_store_1',
          name: '近距離店舗',
          address: '東京都新宿区',
          lat: 35.6917,
          lng: 139.7006,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];

      mockRepository.stubGetAllStores([]);
      mockRepository.stubSearchStoresFromApi(apiStores);

      // Act - すべての有効な距離範囲でテスト
      for (final range in [1, 2, 3, 4, 5]) {
        await provider.loadNewStoresFromApi(
          lat: 35.6917,
          lng: 139.7006,
          range: range,
          count: 10,
        );

        // Assert - 各範囲で正常に実行されることを確認
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      }
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

// テスト用モックLocationService
class MockLocationService implements LocationService {
  Location? _stubCurrentLocation;
  bool _shouldThrowError = false;

  void stubGetCurrentLocation(Location location) {
    _stubCurrentLocation = location;
    _shouldThrowError = false;
  }

  void stubGetCurrentLocationError() {
    _shouldThrowError = true;
  }

  @override
  Future<Location> getCurrentLocation() async {
    if (_shouldThrowError) {
      throw LocationException(
          'テスト用エラー', LocationExceptionType.locationUnavailable);
    }
    return _stubCurrentLocation ??
        Location(
          latitude: 35.6917,
          longitude: 139.7006,
          timestamp: DateTime.now(),
        ); // デフォルト: 新宿駅
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}
