import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_local_datasource.dart';
import '../models/photo_model.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoLocalDatasource _localDatasource;

  PhotoRepositoryImpl(this._localDatasource);

  @override
  Future<List<Photo>> getAllPhotos() async {
    return await _localDatasource.getAllPhotos();
  }

  @override
  Future<List<Photo>> getPhotosByStoreId(String storeId) async {
    return await _localDatasource.getPhotosByStoreId(storeId);
  }

  @override
  Future<List<Photo>> getPhotosByVisitId(String visitId) async {
    return await _localDatasource.getPhotosByVisitId(visitId);
  }

  @override
  Future<Photo?> getPhotoById(String id) async {
    final photoModel = await _localDatasource.getPhotoById(id);
    return photoModel;
  }

  @override
  Future<void> insertPhoto(Photo photo) async {
    final photoModel = PhotoModel.fromEntity(photo);
    await _localDatasource.insertPhoto(photoModel);
  }

  @override
  Future<void> updatePhoto(Photo photo) async {
    final photoModel = PhotoModel.fromEntity(photo);
    await _localDatasource.updatePhoto(photoModel);
  }

  @override
  Future<void> deletePhoto(String id) async {
    await _localDatasource.deletePhoto(id);
  }
}
