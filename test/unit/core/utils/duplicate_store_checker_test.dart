import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/utils/duplicate_store_checker.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('DuplicateStoreChecker', () {
    late Store store1;
    late Store store2;
    late Store store3;

    setUp(() {
      // 新宿駅周辺の店舗
      store1 = Store(
        id: 'store_1',
        name: '新宿中華楼',
        address: '東京都新宿区新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        memo: '',
        createdAt: DateTime.now(),
      );

      // 近接店舗（約50m離れた位置）
      store2 = Store(
        id: 'store_2',
        name: '新宿中華楼',
        address: '東京都新宿区新宿1-1-2',
        lat: 35.6921, // 約44m北
        lng: 139.7006,
        memo: '',
        createdAt: DateTime.now(),
      );

      // 遠距離店舗（約200m離れた位置）
      store3 = Store(
        id: 'store_3',
        name: '渋谷中華楼',
        address: '東京都渋谷区渋谷1-1-1',
        lat: 35.6935, // 約200m北
        lng: 139.7006,
        memo: '',
        createdAt: DateTime.now(),
      );
    });

    group('calculateDistance', () {
      test('should calculate distance between two points correctly', () {
        // Red: 2点間の距離計算テスト
        final distance = DuplicateStoreChecker.calculateDistance(
          LatLng(store1.lat, store1.lng),
          LatLng(store2.lat, store2.lng),
        );

        expect(distance, closeTo(44.0, 10.0)); // 約44m、誤差±10m
      });

      test('should return 0 for identical coordinates', () {
        final distance = DuplicateStoreChecker.calculateDistance(
          LatLng(store1.lat, store1.lng),
          LatLng(store1.lat, store1.lng),
        );

        expect(distance, equals(0.0));
      });
    });

    group('isDuplicate', () {
      test('should detect duplicates within default threshold (110m)', () {
        // Red: デフォルト閾値での重複判定テスト
        final result = DuplicateStoreChecker.isDuplicate(store1, store2);

        expect(result, isTrue); // 44m < 110m なので重複
      });

      test('should not detect duplicates beyond default threshold', () {
        final result = DuplicateStoreChecker.isDuplicate(store1, store3);

        expect(result, isFalse); // 200m > 110m なので非重複
      });

      test('should use custom threshold when provided', () {
        // カスタム閾値30mでテスト
        final result = DuplicateStoreChecker.isDuplicate(
          store1,
          store2,
          threshold: 30.0,
        );

        expect(result, isFalse); // 44m > 30m なので非重複
      });

      test('should detect duplicates with custom threshold 50m', () {
        final result = DuplicateStoreChecker.isDuplicate(
          store1,
          store2,
          threshold: 50.0,
        );

        expect(result, isTrue); // 44m < 50m なので重複
      });
    });

    group('removeDuplicates', () {
      test('should remove duplicates from store list', () {
        // Red: リストからの重複除去テスト
        final stores = [store1, store2, store3];
        final uniqueStores = DuplicateStoreChecker.removeDuplicates(stores);

        expect(uniqueStores.length, equals(2)); // store1とstore2が重複、store3は残る
        expect(uniqueStores, contains(store1)); // 最初の店舗を保持
        expect(uniqueStores, contains(store3)); // 非重複店舗を保持
        expect(uniqueStores, isNot(contains(store2))); // 重複店舗を除去
      });

      test('should preserve order and keep first occurrence', () {
        final stores = [store2, store1, store3]; // 順番を変更
        final uniqueStores = DuplicateStoreChecker.removeDuplicates(stores);

        expect(uniqueStores.length, equals(2));
        expect(uniqueStores.first, equals(store2)); // 最初に出現した方を保持
        expect(uniqueStores.last, equals(store3));
      });

      test('should handle empty list', () {
        final uniqueStores = DuplicateStoreChecker.removeDuplicates([]);

        expect(uniqueStores, isEmpty);
      });

      test('should handle single store list', () {
        final uniqueStores = DuplicateStoreChecker.removeDuplicates([store1]);

        expect(uniqueStores.length, equals(1));
        expect(uniqueStores.first, equals(store1));
      });

      test('should use custom threshold for duplicate removal', () {
        final stores = [store1, store2, store3];
        final uniqueStores = DuplicateStoreChecker.removeDuplicates(
          stores,
          threshold: 30.0, // 30m閾値
        );

        expect(uniqueStores.length, equals(3)); // 30m閾値では全て非重複
      });
    });
  });
}
