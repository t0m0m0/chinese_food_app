import 'package:drift/drift.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';
import 'package:chinese_food_app/domain/entities/photo.dart' as entities;

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
}
