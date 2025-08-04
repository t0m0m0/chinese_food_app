import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Photo;
import 'package:chinese_food_app/data/datasources/photo_local_datasource_drift.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';
import '../../../helpers/test_database_factory.dart';

void main() {
  late AppDatabase database;
  late PhotoLocalDatasourceDrift datasource;

  setUp(() async {
    database = TestDatabaseFactory.createTestDatabase();
    datasource = PhotoLocalDatasourceDrift(database);

    // 外部キー制約のためにテスト用のstoreとvisit_recordレコードを作成
    await database.into(database.stores).insert(StoresCompanion(
          id: const Value('store_1'),
          name: const Value('テスト店舗1'),
          address: const Value('テスト住所1'),
          lat: const Value(35.6812362),
          lng: const Value(139.7649361),
          status: const Value('want_to_go'),
          memo: const Value(''),
          createdAt: Value(DateTime.now().toIso8601String()),
        ));

    await database.into(database.visitRecords).insert(VisitRecordsCompanion(
          id: const Value('visit_1'),
          storeId: const Value('store_1'),
          visitedAt: Value(DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()),
          menu: const Value('テストメニュー'),
          memo: const Value(''),
          createdAt: Value(DateTime.now().toIso8601String()),
        ));
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('PhotoLocalDatasourceDrift Tests', () {
    test('should insert photo successfully', () async {
      // TDD: Red - Drift版での写真挿入テスト
      final photo = Photo(
        id: 'photo_1',
        storeId: 'store_1',
        visitId: 'visit_1',
        filePath: '/storage/photos/test_photo.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo);

      final retrieved = await datasource.getPhotoById('photo_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.filePath, equals('/storage/photos/test_photo.jpg'));
      expect(retrieved.visitId, equals('visit_1'));
    });

    test('should get all photos', () async {
      // TDD: Red - 全写真取得テスト
      final photos = [
        Photo(
          id: 'photo_1',
          storeId: 'store_1',
          filePath: '/storage/photos/photo1.jpg',
          createdAt: DateTime(2023, 12, 1),
        ),
        Photo(
          id: 'photo_2',
          storeId: 'store_1',
          visitId: 'visit_1',
          filePath: '/storage/photos/photo2.jpg',
          createdAt: DateTime(2023, 12, 2),
        ),
      ];

      for (final photo in photos) {
        await datasource.insertPhoto(photo);
      }

      final allPhotos = await datasource.getAllPhotos();
      expect(allPhotos.length, equals(2));

      // 作成日時の降順でソートされていることを確認
      expect(
          allPhotos.first.createdAt.isAfter(allPhotos.last.createdAt), isTrue);
    });

    test('should get photos by store ID', () async {
      // TDD: Red - 店舗ID別写真取得テスト
      final photos = [
        Photo(
          id: 'photo_store1_1',
          storeId: 'store_1',
          filePath: '/storage/photos/store1_1.jpg',
          createdAt: DateTime.now(),
        ),
        Photo(
          id: 'photo_store1_2',
          storeId: 'store_1',
          filePath: '/storage/photos/store1_2.jpg',
          createdAt: DateTime.now(),
        ),
      ];

      for (final photo in photos) {
        await datasource.insertPhoto(photo);
      }

      final store1Photos = await datasource.getPhotosByStoreId('store_1');
      expect(store1Photos.length, equals(2));
      expect(store1Photos.every((p) => p.storeId == 'store_1'), isTrue);
    });

    test('should get photos by visit ID', () async {
      // TDD: Red - 訪問記録ID別写真取得テスト
      final photos = [
        Photo(
          id: 'photo_visit1_1',
          storeId: 'store_1',
          visitId: 'visit_1',
          filePath: '/storage/photos/visit1_1.jpg',
          createdAt: DateTime.now(),
        ),
        Photo(
          id: 'photo_visit1_2',
          storeId: 'store_1',
          visitId: 'visit_1',
          filePath: '/storage/photos/visit1_2.jpg',
          createdAt: DateTime.now(),
        ),
        Photo(
          id: 'photo_no_visit',
          storeId: 'store_1',
          filePath: '/storage/photos/no_visit.jpg',
          createdAt: DateTime.now(),
        ),
      ];

      for (final photo in photos) {
        await datasource.insertPhoto(photo);
      }

      final visit1Photos = await datasource.getPhotosByVisitId('visit_1');
      expect(visit1Photos.length, equals(2));
      expect(visit1Photos.every((p) => p.visitId == 'visit_1'), isTrue);
    });

    test('should update photo successfully', () async {
      // TDD: Red - 写真更新テスト
      final original = Photo(
        id: 'photo_update',
        storeId: 'store_1',
        filePath: '/storage/photos/original.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(original);

      final updated = original.copyWith(
        filePath: '/storage/photos/updated.jpg',
        visitId: 'visit_1',
      );

      await datasource.updatePhoto(updated);

      final retrieved = await datasource.getPhotoById('photo_update');
      expect(retrieved!.filePath, equals('/storage/photos/updated.jpg'));
      expect(retrieved.visitId, equals('visit_1'));
    });

    test('should delete photo successfully', () async {
      // TDD: Red - 写真削除テスト
      final photo = Photo(
        id: 'photo_delete',
        storeId: 'store_1',
        filePath: '/storage/photos/delete_test.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo);
      expect(await datasource.getPhotoById('photo_delete'), isNotNull);

      await datasource.deletePhoto('photo_delete');
      expect(await datasource.getPhotoById('photo_delete'), isNull);
    });

    test('should return null for non-existent photo', () async {
      // TDD: Red - 存在しない写真の取得テスト
      final result = await datasource.getPhotoById('non_existent');
      expect(result, isNull);
    });

    test('should handle photos without visit ID', () async {
      // TDD: Red - visit_id=nullの写真処理テスト
      final photo = Photo(
        id: 'photo_no_visit',
        storeId: 'store_1',
        filePath: '/storage/photos/no_visit.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo);

      final retrieved = await datasource.getPhotoById('photo_no_visit');
      expect(retrieved, isNotNull);
      expect(retrieved!.visitId, isNull);
    });
  });
}
