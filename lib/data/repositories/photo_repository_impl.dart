import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_local_datasource.dart';
import '../models/photo_model.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoLocalDatasource _localDatasource;

  PhotoRepositoryImpl(this._localDatasource);

  @override
  Future<List<Photo>> getAllPhotos() async {
    final photoModels = await _localDatasource.getAllPhotos();
    return photoModels.cast<Photo>();
  }

  @override
  Future<List<Photo>> getPhotosByStoreId(String storeId) async {
    final photoModels = await _localDatasource.getPhotosByStoreId(storeId);
    return photoModels.cast<Photo>();
  }

  @override
  Future<List<Photo>> getPhotosByVisitId(String visitId) async {
    final photoModels = await _localDatasource.getPhotosByVisitId(visitId);
    return photoModels.cast<Photo>();
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