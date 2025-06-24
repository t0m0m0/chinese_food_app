import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('Store Entity Tests', () {
    test('should create Store entity with valid data', () {
      // Red: This test should fail initially - Store entity doesn't exist yet
      final store = Store(
        id: 'test-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: 'テスト用の店舗',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(store.id, 'test-store-id');
      expect(store.name, '中華料理 テスト');
      expect(store.address, '東京都渋谷区テスト1-1-1');
      expect(store.lat, 35.6762);
      expect(store.lng, 139.6503);
      expect(store.status, StoreStatus.wantToGo);
      expect(store.memo, 'テスト用の店舗');
      expect(store.createdAt, DateTime(2025, 6, 23, 16, 0, 0));
    });

    test('should create Store entity with default memo', () {
      final store = Store(
        id: 'test-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(store.memo, isEmpty);
    });

    test('should support all store status types', () {
      final statuses = [
        StoreStatus.wantToGo,
        StoreStatus.visited,
        StoreStatus.bad,
      ];

      for (final status in statuses) {
        final store = Store(
          id: 'test-store-id',
          name: '中華料理 テスト',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: status,
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        expect(store.status, status);
      }
    });

    test('should validate latitude range', () {
      expect(
          () => Store(
                id: 'test-store-id',
                name: '中華料理 テスト',
                address: '東京都渋谷区テスト1-1-1',
                lat: 91.0, // 無効な緯度
                lng: 139.6503,
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Store(
                id: 'test-store-id',
                name: '中華料理 テスト',
                address: '東京都渋谷区テスト1-1-1',
                lat: -91.0, // 無効な緯度
                lng: 139.6503,
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should validate longitude range', () {
      expect(
          () => Store(
                id: 'test-store-id',
                name: '中華料理 テスト',
                address: '東京都渋谷区テスト1-1-1',
                lat: 35.6762,
                lng: 181.0, // 無効な経度
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Store(
                id: 'test-store-id',
                name: '中華料理 テスト',
                address: '東京都渋谷区テスト1-1-1',
                lat: 35.6762,
                lng: -181.0, // 無効な経度
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should validate required fields', () {
      expect(
          () => Store(
                id: '',
                name: '中華料理 テスト',
                address: '東京都渋谷区テスト1-1-1',
                lat: 35.6762,
                lng: 139.6503,
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Store(
                id: 'test-store-id',
                name: '',
                address: '東京都渋谷区テスト1-1-1',
                lat: 35.6762,
                lng: 139.6503,
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Store(
                id: 'test-store-id',
                name: '中華料理 テスト',
                address: '',
                lat: 35.6762,
                lng: 139.6503,
                status: StoreStatus.wantToGo,
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should convert to and from JSON', () {
      final originalStore = Store(
        id: 'test-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: 'テスト用の店舗',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final json = originalStore.toJson();
      final reconstructedStore = Store.fromJson(json);

      expect(reconstructedStore.id, originalStore.id);
      expect(reconstructedStore.name, originalStore.name);
      expect(reconstructedStore.address, originalStore.address);
      expect(reconstructedStore.lat, originalStore.lat);
      expect(reconstructedStore.lng, originalStore.lng);
      expect(reconstructedStore.status, originalStore.status);
      expect(reconstructedStore.memo, originalStore.memo);
      expect(reconstructedStore.createdAt, originalStore.createdAt);
    });

    test('should support equality comparison', () {
      final store1 = Store(
        id: 'test-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: 'テスト用の店舗',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final store2 = Store(
        id: 'test-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: 'テスト用の店舗',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final store3 = Store(
        id: 'different-store-id',
        name: '中華料理 テスト',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: 'テスト用の店舗',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(store1, equals(store2));
      expect(store1.hashCode, equals(store2.hashCode));
      expect(store1, isNot(equals(store3)));
    });
  });
}
