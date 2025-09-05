import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/store_cache_manager.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/core/config/cache_config.dart';

void main() {
  group('StoreCacheManager', () {
    late StoreCacheManager cacheManager;
    late List<Store> testStores;

    setUp(() {
      cacheManager = StoreCacheManager();
      testStores = [
        Store(
          id: '1',
          name: 'Test Store 1',
          address: 'Test Address 1',
          lat: 35.6917,
          lng: 139.7006,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '2',
          name: 'Test Store 2',
          address: 'Test Address 2',
          lat: 35.6918,
          lng: 139.7007,
          status: StoreStatus.visited,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '3',
          name: 'Test Store 3',
          address: 'Test Address 3',
          lat: 35.6919,
          lng: 139.7008,
          status: StoreStatus.bad,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '4',
          name: 'Test Store 4',
          address: 'Test Address 4',
          lat: 35.6920,
          lng: 139.7009,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('should filter want to go stores', () {
      final wantToGoStores = cacheManager.getWantToGoStores(testStores);
      expect(wantToGoStores.length, 1);
      expect(wantToGoStores.first.id, '1');
    });

    test('should filter visited stores', () {
      final visitedStores = cacheManager.getVisitedStores(testStores);
      expect(visitedStores.length, 1);
      expect(visitedStores.first.id, '2');
    });

    test('should filter bad stores', () {
      final badStores = cacheManager.getBadStores(testStores);
      expect(badStores.length, 1);
      expect(badStores.first.id, '3');
    });

    test('should filter new stores (no status)', () {
      final newStores = cacheManager.getNewStores(testStores);
      expect(newStores.length, 1);
      expect(newStores.first.id, '4');
    });

    test('should cache results for performance', () {
      // 最初の呼び出し
      final wantToGoStores1 = cacheManager.getWantToGoStores(testStores);

      // 2回目の呼び出し - キャッシュから取得される
      final wantToGoStores2 = cacheManager.getWantToGoStores(testStores);

      // 同じインスタンス（キャッシュされている）
      expect(identical(wantToGoStores1, wantToGoStores2), true);
    });

    test('should clear cache manually', () {
      final wantToGoStores1 = cacheManager.getWantToGoStores(testStores);

      cacheManager.clearCache();

      final wantToGoStores2 = cacheManager.getWantToGoStores(testStores);

      // キャッシュクリア後は異なるインスタンス
      expect(identical(wantToGoStores1, wantToGoStores2), false);
    });

    test('should check if cache is expired', () {
      expect(cacheManager.isCacheExpired(), false);

      cacheManager.clearCache();

      // 最初はキャッシュが期限切れでない
      expect(cacheManager.isCacheExpired(), false);
    });

    test('should use cache config for expiry time', () {
      // キャッシュ設定からミリ秒を取得できることを確認
      expect(CacheConfig.storeCacheMaxAgeMilliseconds, greaterThan(0));

      // 開発環境では短い期限が設定されていることを確認
      if (CacheConfig.isDevelopment) {
        expect(CacheConfig.activeStoreCacheMaxAge,
            equals(CacheConfig.debugCacheMaxAge));
      } else {
        expect(CacheConfig.activeStoreCacheMaxAge,
            equals(CacheConfig.storeCacheMaxAge));
      }
    });
  });
}
