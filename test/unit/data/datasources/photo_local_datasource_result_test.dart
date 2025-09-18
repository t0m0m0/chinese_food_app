import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store, VisitRecord, Photo;
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/data/datasources/photo_local_datasource.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';
import '../../../helpers/test_database_factory.dart';

void main() {
  late AppDatabase database;
  late PhotoLocalDatasourceImpl datasource;

  setUp(() {
    database = TestDatabaseFactory.createTestDatabase();
    datasource = PhotoLocalDatasourceImpl(database);
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('PhotoLocalDatasource Result<T> Pattern Tests', () {
    test(
        'insertPhotoResult should return Success when photo is inserted successfully',
        () async {
      // TDD Red: Result<T>版の写真挿入テスト
      final photo = Photo(
        id: 'test_photo_result_1',
        storeId: 'store_123',
        visitId: null,
        filePath: '/path/to/test_image.jpg',
        createdAt: DateTime.now(),
      );

      final result = await datasource.insertPhotoResult(photo);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく挿入されているか確認
      final retrieved = await datasource.getPhotoById('test_photo_result_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.filePath, equals('/path/to/test_image.jpg'));
    });

    test('getPhotoByIdResult should return Success with photo when found',
        () async {
      // TDD Red: Result<T>版の写真取得テスト
      final photo = Photo(
        id: 'test_photo_result_2',
        storeId: 'store_456',
        visitId: 'visit_789',
        filePath: '/path/to/another_image.png',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo);

      final result = await datasource.getPhotoByIdResult('test_photo_result_2');

      expect(result.isSuccess, true);
      expect(result, isA<Success<Photo?>>());
      final retrievedPhoto = (result as Success<Photo?>).data;
      expect(retrievedPhoto, isNotNull);
      expect(retrievedPhoto!.filePath, equals('/path/to/another_image.png'));
    });

    test(
        'getPhotoByIdResult should return Success with null when photo not found',
        () async {
      // TDD Red: 存在しない写真のResult<T>版取得テスト
      final result = await datasource.getPhotoByIdResult('non_existent_photo');

      expect(result.isSuccess, true);
      expect(result, isA<Success<Photo?>>());
      final retrievedPhoto = (result as Success<Photo?>).data;
      expect(retrievedPhoto, isNull);
    });

    test('getAllPhotosResult should return Success with photo list', () async {
      // TDD Red: Result<T>版の全写真取得テスト
      final photo1 = Photo(
        id: 'test_photo_result_3',
        storeId: 'store_111',
        visitId: null,
        filePath: '/path/to/photo1.jpg',
        createdAt: DateTime.now(),
      );

      final photo2 = Photo(
        id: 'test_photo_result_4',
        storeId: 'store_222',
        visitId: 'visit_333',
        filePath: '/path/to/photo2.png',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo1);
      await datasource.insertPhoto(photo2);

      final result = await datasource.getAllPhotosResult();

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<Photo>>>());
      final photos = (result as Success<List<Photo>>).data;
      expect(photos.length, greaterThanOrEqualTo(2));

      final filePaths = photos.map((p) => p.filePath).toList();
      expect(filePaths,
          containsAll(['/path/to/photo1.jpg', '/path/to/photo2.png']));
    });

    test('getPhotosByStoreIdResult should return Success with filtered photos',
        () async {
      // TDD Red: Result<T>版の店舗別写真取得テスト
      const targetStoreId = 'store_result_test';

      final photo1 = Photo(
        id: 'test_photo_result_5',
        storeId: targetStoreId,
        visitId: null,
        filePath: '/path/to/target_store_photo1.jpg',
        createdAt: DateTime.now(),
      );

      final photo2 = Photo(
        id: 'test_photo_result_6',
        storeId: targetStoreId,
        visitId: 'visit_123',
        filePath: '/path/to/target_store_photo2.png',
        createdAt: DateTime.now(),
      );

      final photo3 = Photo(
        id: 'test_photo_result_7',
        storeId: 'other_store',
        visitId: null,
        filePath: '/path/to/other_store_photo.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo1);
      await datasource.insertPhoto(photo2);
      await datasource.insertPhoto(photo3);

      final result = await datasource.getPhotosByStoreIdResult(targetStoreId);

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<Photo>>>());
      final filteredPhotos = (result as Success<List<Photo>>).data;
      expect(filteredPhotos.every((p) => p.storeId == targetStoreId), true);

      final filePaths = filteredPhotos.map((p) => p.filePath).toList();
      expect(
          filePaths,
          containsAll([
            '/path/to/target_store_photo1.jpg',
            '/path/to/target_store_photo2.png'
          ]));
      expect(filePaths, isNot(contains('/path/to/other_store_photo.jpg')));
    });

    test(
        'getPhotosByVisitIdResult should return Success with visit-filtered photos',
        () async {
      // TDD Red: Result<T>版の訪問記録別写真取得テスト
      const targetVisitId = 'visit_result_test';

      final photo1 = Photo(
        id: 'test_photo_result_8',
        storeId: 'store_888',
        visitId: targetVisitId,
        filePath: '/path/to/visit_photo1.jpg',
        createdAt: DateTime.now(),
      );

      final photo2 = Photo(
        id: 'test_photo_result_9',
        storeId: 'store_999',
        visitId: targetVisitId,
        filePath: '/path/to/visit_photo2.png',
        createdAt: DateTime.now(),
      );

      final photo3 = Photo(
        id: 'test_photo_result_10',
        storeId: 'store_888',
        visitId: 'other_visit',
        filePath: '/path/to/other_visit_photo.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo1);
      await datasource.insertPhoto(photo2);
      await datasource.insertPhoto(photo3);

      final result = await datasource.getPhotosByVisitIdResult(targetVisitId);

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<Photo>>>());
      final filteredPhotos = (result as Success<List<Photo>>).data;
      expect(filteredPhotos.every((p) => p.visitId == targetVisitId), true);

      final filePaths = filteredPhotos.map((p) => p.filePath).toList();
      expect(
          filePaths,
          containsAll(
              ['/path/to/visit_photo1.jpg', '/path/to/visit_photo2.png']));
      expect(filePaths, isNot(contains('/path/to/other_visit_photo.jpg')));
    });

    test(
        'updatePhotoResult should return Success when photo is updated successfully',
        () async {
      // TDD Red: Result<T>版の写真更新テスト
      final originalPhoto = Photo(
        id: 'test_photo_result_11',
        storeId: 'store_update',
        visitId: null,
        filePath: '/path/to/original.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(originalPhoto);

      final updatedPhoto = originalPhoto.copyWith(
        filePath: '/path/to/updated.jpg',
        visitId: 'visit_updated',
      );

      final result = await datasource.updatePhotoResult(updatedPhoto);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく更新されているか確認
      final retrieved = await datasource.getPhotoById('test_photo_result_11');
      expect(retrieved!.filePath, equals('/path/to/updated.jpg'));
      expect(retrieved.visitId, equals('visit_updated'));
    });

    test(
        'deletePhotoResult should return Success when photo is deleted successfully',
        () async {
      // TDD Red: Result<T>版の写真削除テスト
      final photo = Photo(
        id: 'test_photo_result_12',
        storeId: 'store_delete',
        visitId: null,
        filePath: '/path/to/delete_test.jpg',
        createdAt: DateTime.now(),
      );

      await datasource.insertPhoto(photo);

      final result = await datasource.deletePhotoResult('test_photo_result_12');

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく削除されているか確認
      final retrieved = await datasource.getPhotoById('test_photo_result_12');
      expect(retrieved, isNull);
    });
  });
}
