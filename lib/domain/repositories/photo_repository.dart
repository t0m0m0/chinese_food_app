import '../entities/photo.dart';

abstract class PhotoRepository {
  Future<List<Photo>> getAllPhotos();
  Future<List<Photo>> getPhotosByStoreId(String storeId);
  Future<List<Photo>> getPhotosByVisitId(String visitId);
  Future<Photo?> getPhotoById(String id);
  Future<void> insertPhoto(Photo photo);
  Future<void> updatePhoto(Photo photo);
  Future<void> deletePhoto(String id);
}
