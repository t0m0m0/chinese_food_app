import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/cache_config.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';

void main() {
  group('CacheConfig', () {
    tearDown(() {
      // テスト後にEnvironmentConfigのテストコンテキストをクリア
      EnvironmentConfig.clearTestContext();
    });

    test('should provide default cache durations', () {
      expect(CacheConfig.storeCacheMaxAge, equals(const Duration(seconds: 30)));
      expect(CacheConfig.searchCacheMaxAge, equals(const Duration(minutes: 5)));
      expect(
          CacheConfig.locationCacheMaxAge, equals(const Duration(minutes: 10)));
      expect(CacheConfig.imageCacheMaxAge, equals(const Duration(hours: 24)));
      expect(CacheConfig.debugCacheMaxAge, equals(const Duration(seconds: 5)));
    });

    test('should provide cache size limits', () {
      expect(CacheConfig.maxCacheEntries, equals(1000));
      expect(CacheConfig.maxLargeCacheEntries, equals(100));
      expect(CacheConfig.cacheCleanupProbability, equals(0.1));
      expect(CacheConfig.memoryCriticalThresholdMB, equals(100));
    });

    test('should provide environment-aware store cache duration', () {
      final activeDuration = CacheConfig.activeStoreCacheMaxAge;

      if (CacheConfig.isDevelopment) {
        expect(activeDuration, equals(CacheConfig.debugCacheMaxAge));
      } else {
        expect(activeDuration, equals(CacheConfig.storeCacheMaxAge));
      }
    });

    test('should convert store cache duration to milliseconds', () {
      final milliseconds = CacheConfig.storeCacheMaxAgeMilliseconds;
      final expectedMilliseconds =
          CacheConfig.activeStoreCacheMaxAge.inMilliseconds;

      expect(milliseconds, equals(expectedMilliseconds));
      expect(milliseconds, greaterThan(0));
    });

    test('should use debug cache duration in development environment', () {
      // 開発環境の場合
      if (CacheConfig.isDevelopment) {
        expect(CacheConfig.storeCacheMaxAgeMilliseconds,
            equals(const Duration(seconds: 5).inMilliseconds));
      }
    });

    test('should provide consistent configuration values', () {
      // デバッグ期間は本番期間より短い
      expect(CacheConfig.debugCacheMaxAge.inMilliseconds,
          lessThan(CacheConfig.storeCacheMaxAge.inMilliseconds));

      // 検索キャッシュは店舗キャッシュより長い
      expect(CacheConfig.searchCacheMaxAge.inMilliseconds,
          greaterThan(CacheConfig.storeCacheMaxAge.inMilliseconds));

      // 位置情報キャッシュは検索キャッシュより長い
      expect(CacheConfig.locationCacheMaxAge.inMilliseconds,
          greaterThan(CacheConfig.searchCacheMaxAge.inMilliseconds));

      // 画像キャッシュは最も長い
      expect(CacheConfig.imageCacheMaxAge.inMilliseconds,
          greaterThan(CacheConfig.locationCacheMaxAge.inMilliseconds));
    });

    test('isDevelopment should use EnvironmentConfig', () {
      // テスト環境ではEnvironmentConfigの状態をリセット
      EnvironmentConfig.resetForTesting();

      // CacheConfig.isDevelopmentはEnvironmentConfig.isDevelopmentまたは
      // EnvironmentConfig.isTestに基づいて判定される
      final envIsDevelopmentOrTest =
          EnvironmentConfig.isDevelopment || EnvironmentConfig.isTest;
      expect(CacheConfig.isDevelopment, equals(envIsDevelopmentOrTest));
    });
  });
}
