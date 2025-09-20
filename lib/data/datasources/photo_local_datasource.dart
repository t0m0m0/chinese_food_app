import 'package:drift/drift.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';
import 'package:chinese_food_app/domain/entities/photo.dart' as entities;
import '../../core/types/result.dart';
import '../../core/exceptions/base_exception.dart';

/// 写真データのローカルデータソースインターフェース
abstract class PhotoLocalDatasource {
  /// 写真を挿入
  Future<void> insertPhoto(entities.Photo photo);

  /// IDで写真を取得
  Future<entities.Photo?> getPhotoById(String id);

  /// 全写真を取得
  Future<List<entities.Photo>> getAllPhotos();

  /// 店舗IDで写真を取得
  Future<List<entities.Photo>> getPhotosByStoreId(String storeId);

  /// 訪問記録IDで写真を取得
  Future<List<entities.Photo>> getPhotosByVisitId(String visitId);

  /// 写真を更新
  Future<void> updatePhoto(entities.Photo photo);

  /// 写真を削除
  Future<void> deletePhoto(String id);

  // Result&lt;T&gt;パターンに対応したメソッド群
  /// Result&lt;T&gt;版: 写真を挿入
  Future<Result<void>> insertPhotoResult(entities.Photo photo);

  /// Result&lt;T&gt;版: IDで写真を取得
  Future<Result<entities.Photo?>> getPhotoByIdResult(String id);

  /// Result&lt;T&gt;版: 全写真を取得
  Future<Result<List<entities.Photo>>> getAllPhotosResult();

  /// Result&lt;T&gt;版: 店舗IDで写真を取得
  Future<Result<List<entities.Photo>>> getPhotosByStoreIdResult(String storeId);

  /// Result&lt;T&gt;版: 訪問記録IDで写真を取得
  Future<Result<List<entities.Photo>>> getPhotosByVisitIdResult(String visitId);

  /// Result&lt;T&gt;版: 写真を更新
  Future<Result<void>> updatePhotoResult(entities.Photo photo);

  /// Result&lt;T&gt;版: 写真を削除
  Future<Result<void>> deletePhotoResult(String id);
}

/// 写真データのローカルデータソース実装
///
/// Driftを使用したSQLiteデータベースアクセスを提供
class PhotoLocalDatasourceImpl implements PhotoLocalDatasource {
  final AppDatabase _database;

  PhotoLocalDatasourceImpl(this._database);

  /// 写真を挿入
  @override
  Future<void> insertPhoto(entities.Photo photo) async {
    await _database.into(_database.photos).insert(_photoToCompanion(photo));
  }

  /// 写真IDで取得
  @override
  Future<entities.Photo?> getPhotoById(String id) async {
    final query = _database.select(_database.photos)
      ..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _driftPhotoToEntity(result) : null;
  }

  /// 全写真を取得（作成日時降順）
  @override
  Future<List<entities.Photo>> getAllPhotos() async {
    final query = _database.select(_database.photos)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((photo) => _driftPhotoToEntity(photo)).toList();
  }

  /// 店舗IDで写真を取得
  @override
  Future<List<entities.Photo>> getPhotosByStoreId(String storeId) async {
    final query = _database.select(_database.photos)
      ..where((tbl) => tbl.storeId.equals(storeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((photo) => _driftPhotoToEntity(photo)).toList();
  }

  /// 訪問記録IDで写真を取得
  @override
  Future<List<entities.Photo>> getPhotosByVisitId(String visitId) async {
    final query = _database.select(_database.photos)
      ..where((tbl) => tbl.visitId.equals(visitId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((photo) => _driftPhotoToEntity(photo)).toList();
  }

  /// 写真を更新
  @override
  Future<void> updatePhoto(entities.Photo photo) async {
    await (_database.update(_database.photos)
          ..where((tbl) => tbl.id.equals(photo.id)))
        .write(_photoToCompanion(photo));
  }

  /// 写真を削除
  @override
  Future<void> deletePhoto(String id) async {
    await (_database.delete(_database.photos)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// EntityをDrift Companionに変換
  PhotosCompanion _photoToCompanion(entities.Photo photo) {
    return PhotosCompanion(
      id: Value(photo.id),
      storeId: Value(photo.storeId),
      visitId: Value(photo.visitId),
      filePath: Value(photo.filePath),
      createdAt: Value(photo.createdAt.toIso8601String()),
    );
  }

  /// Drift PhotoをEntityに変換
  entities.Photo _driftPhotoToEntity(Photo photo) {
    return entities.Photo(
      id: photo.id,
      storeId: photo.storeId,
      visitId: photo.visitId,
      filePath: photo.filePath,
      createdAt: DateTime.parse(photo.createdAt),
    );
  }

  // Result<T>パターン実装
  @override
  Future<Result<void>> insertPhotoResult(entities.Photo photo) async {
    try {
      await insertPhoto(photo);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(BaseException('Failed to insert photo: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photo insertion: ${e.toString()}'));
    }
  }

  @override
  Future<Result<entities.Photo?>> getPhotoByIdResult(String id) async {
    try {
      final photo = await getPhotoById(id);
      return Success(photo);
    } on Exception catch (e) {
      return Failure(
          BaseException('Failed to get photo by id: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photo retrieval: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<entities.Photo>>> getAllPhotosResult() async {
    try {
      final photos = await getAllPhotos();
      return Success(photos);
    } on Exception catch (e) {
      return Failure(
          BaseException('Failed to get all photos: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photos retrieval: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<entities.Photo>>> getPhotosByStoreIdResult(
      String storeId) async {
    try {
      final photos = await getPhotosByStoreId(storeId);
      return Success(photos);
    } on Exception catch (e) {
      return Failure(
          BaseException('Failed to get photos by store id: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photos retrieval by store id: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<entities.Photo>>> getPhotosByVisitIdResult(
      String visitId) async {
    try {
      final photos = await getPhotosByVisitId(visitId);
      return Success(photos);
    } on Exception catch (e) {
      return Failure(
          BaseException('Failed to get photos by visit id: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photos retrieval by visit id: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updatePhotoResult(entities.Photo photo) async {
    try {
      await updatePhoto(photo);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(BaseException('Failed to update photo: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photo update: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deletePhotoResult(String id) async {
    try {
      await deletePhoto(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(BaseException('Failed to delete photo: ${e.toString()}'));
    } catch (e) {
      return Failure(BaseException(
          'Unexpected error during photo deletion: ${e.toString()}'));
    }
  }
}
