import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store;
import 'package:chinese_food_app/data/datasources/store_local_datasource_drift.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../../helpers/test_database_factory.dart';

void main() {
  late AppDatabase database;
  late StoreLocalDatasourceDrift datasource;

  setUp(() {
    database = TestDatabaseFactory.createTestDatabase();
    datasource = StoreLocalDatasourceDrift(database);
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('Pagination Tests - Issue #84', () {
    test('should implement efficient pagination for large datasets', () async {
      // TDD: Red - 大量データのページネーション効率化テスト

      // 1000件のテストデータを準備
      final stores = List.generate(
          1000,
          (index) => Store(
                id: 'store_${index.toString().padLeft(4, '0')}',
                name: '店舗_$index',
                address: '住所_$index',
                lat: 35.6580339 + (index * 0.001),
                lng: 139.7016358 + (index * 0.001),
                status: [
                  StoreStatus.wantToGo,
                  StoreStatus.visited,
                  StoreStatus.bad
                ][index % 3],
                memo: 'メモ_$index',
                createdAt: DateTime.now().subtract(Duration(days: index)),
              ));

      // バッチでデータを挿入
      await datasource.insertStoresBatch(stores);

      // ページネーション実行（20件ずつ、3ページ取得）
      final page1 = await datasource.getStoresPaginated(
        page: 1,
        pageSize: 20,
        status: StoreStatus.wantToGo,
      );

      final page2 = await datasource.getStoresPaginated(
        page: 2,
        pageSize: 20,
        status: StoreStatus.wantToGo,
      );

      final page3 = await datasource.getStoresPaginated(
        page: 3,
        pageSize: 20,
        status: StoreStatus.wantToGo,
      );

      // 結果検証
      expect(page1.length, equals(20), reason: 'Page 1 should have 20 items');
      expect(page2.length, equals(20), reason: 'Page 2 should have 20 items');
      expect(page3.length, equals(20), reason: 'Page 3 should have 20 items');

      // 重複がないことを確認
      final allIds = <String>{};
      allIds.addAll(page1.map((s) => s.id));
      allIds.addAll(page2.map((s) => s.id));
      allIds.addAll(page3.map((s) => s.id));
      expect(allIds.length, equals(60), reason: 'All items should be unique');

      // 順序確認（作成日時降順）
      for (int i = 1; i < page1.length; i++) {
        expect(
            page1[i - 1].createdAt.isAfter(page1[i].createdAt) ||
                page1[i - 1].createdAt.isAtSameMomentAs(page1[i].createdAt),
            isTrue,
            reason: 'Items should be ordered by createdAt desc');
      }
    });

    test('should handle pagination boundaries correctly', () async {
      // TDD: Red - ページネーション境界値テスト

      // 25件のテストデータ（ページサイズ10で3ページ + 5件）
      final stores = List.generate(
          25,
          (index) => Store(
                id: 'boundary_$index',
                name: '境界テスト店_$index',
                address: '住所_$index',
                lat: 35.6580339,
                lng: 139.7016358,
                status: StoreStatus.visited,
                createdAt: DateTime.now().subtract(Duration(minutes: index)),
              ));

      await datasource.insertStoresBatch(stores);

      // ページ境界値での取得
      final page1 = await datasource.getStoresPaginated(page: 1, pageSize: 10);
      final page2 = await datasource.getStoresPaginated(page: 2, pageSize: 10);
      final page3 = await datasource.getStoresPaginated(page: 3, pageSize: 10);
      final page4 = await datasource.getStoresPaginated(
          page: 4, pageSize: 10); // 存在しないページ

      expect(page1.length, equals(10), reason: 'Page 1 should have 10 items');
      expect(page2.length, equals(10), reason: 'Page 2 should have 10 items');
      expect(page3.length, equals(5), reason: 'Page 3 should have 5 items');
      expect(page4.length, equals(0), reason: 'Page 4 should be empty');
    });

    test('should optimize performance with indexed queries', () async {
      // TDD: Red - インデックス最適化によるページネーション性能テスト

      // 大量データで性能測定
      final stores = List.generate(
          5000,
          (index) => Store(
                id: 'perf_test_$index',
                name: '性能テスト店_$index',
                address: '住所_$index',
                lat: 35.6580339,
                lng: 139.7016358,
                status: StoreStatus.wantToGo,
                createdAt: DateTime.now().subtract(Duration(seconds: index)),
              ));

      await datasource.insertStoresBatch(stores);

      // パフォーマンス測定
      final stopwatch = Stopwatch()..start();

      // 複数ページを連続取得（通常のユーザー操作をシミュレート）
      final pages = <List<Store>>[];
      for (int page = 1; page <= 10; page++) {
        final result = await datasource.getStoresPaginated(
          page: page,
          pageSize: 50,
          status: StoreStatus.wantToGo,
        );
        pages.add(result);
      }

      stopwatch.stop();

      // 性能要件：10ページ分（500件）の取得が2秒以内
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Pagination should be optimized with proper indexing');

      // 機能確認：正しくページ分割されている
      expect(pages.length, equals(10));
      expect(pages.every((page) => page.length == 50), isTrue,
          reason: 'Each page should have exactly 50 items');
    });

    test('should support search with pagination', () async {
      // TDD: Red - 検索結果のページネーション対応テスト

      final stores = [
        ...List.generate(
            30,
            (index) => Store(
                  id: 'ramen_$index',
                  name: 'ラーメン店_$index',
                  address: '住所_$index',
                  lat: 35.6580339,
                  lng: 139.7016358,
                  status: StoreStatus.wantToGo,
                  createdAt: DateTime.now().subtract(Duration(minutes: index)),
                )),
        ...List.generate(
            20,
            (index) => Store(
                  id: 'sushi_$index',
                  name: '寿司店_$index',
                  address: '住所_$index',
                  lat: 35.6580339,
                  lng: 139.7016358,
                  status: StoreStatus.visited,
                  createdAt:
                      DateTime.now().subtract(Duration(minutes: index + 30)),
                )),
      ];

      await datasource.insertStoresBatch(stores);

      // 検索結果のページネーション
      final searchPage1 = await datasource.searchStoresPaginated(
        query: 'ラーメン',
        page: 1,
        pageSize: 10,
      );

      final searchPage2 = await datasource.searchStoresPaginated(
        query: 'ラーメン',
        page: 2,
        pageSize: 10,
      );

      final searchPage3 = await datasource.searchStoresPaginated(
        query: 'ラーメン',
        page: 3,
        pageSize: 10,
      );

      // 検索結果の検証
      expect(searchPage1.length, equals(10));
      expect(searchPage2.length, equals(10));
      expect(searchPage3.length, equals(10));

      // 全てラーメン店であることを確認
      expect(searchPage1.every((s) => s.name.contains('ラーメン')), isTrue);
      expect(searchPage2.every((s) => s.name.contains('ラーメン')), isTrue);
      expect(searchPage3.every((s) => s.name.contains('ラーメン')), isTrue);
    });
  });
}
