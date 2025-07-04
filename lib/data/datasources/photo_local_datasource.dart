import '../../domain/entities/photo.dart';

/// 写真データのローカルデータソースインターフェース
abstract class PhotoLocalDatasource {
  /// 写真を挿入
  Future<void> insertPhoto(Photo photo);

  /// IDで写真を取得
  Future<Photo?> getPhotoById(String id);

  /// 全写真を取得
  Future<List<Photo>> getAllPhotos();

  /// 店舗IDで写真を取得
  Future<List<Photo>> getPhotosByStoreId(String storeId);

  /// 訪問記録IDで写真を取得
  Future<List<Photo>> getPhotosByVisitId(String visitId);

  /// 写真を更新
  Future<void> updatePhoto(Photo photo);

  /// 写真を削除
  Future<void> deletePhoto(String id);
}
