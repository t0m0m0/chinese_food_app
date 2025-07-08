import 'dart:io';
import 'package:uuid/uuid.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';
import '../../core/services/photo_service.dart';

/// 画像選択UseCase
class PickImageUsecase {
  final PhotoRepository _photoRepository;
  final PhotoService _photoService;
  final Uuid _uuid = const Uuid();

  PickImageUsecase(this._photoRepository, this._photoService);

  /// カメラから写真を撮影して保存
  Future<Photo> pickFromCamera(String storeId, {String? visitId}) async {
    final file = await _photoService.takePhotoFromCamera();

    if (file == null) {
      throw PhotoServiceException('画像の撮影がキャンセルされました');
    }

    return await _savePhoto(file, storeId, visitId);
  }

  /// ギャラリーから写真を選択して保存
  Future<Photo> pickFromGallery(String storeId, {String? visitId}) async {
    final file = await _photoService.pickPhotoFromGallery();

    if (file == null) {
      throw PhotoServiceException('画像の選択がキャンセルされました');
    }

    return await _savePhoto(file, storeId, visitId);
  }

  /// 写真をデータベースに保存
  Future<Photo> _savePhoto(File file, String storeId, String? visitId) async {
    final photo = Photo(
      id: _uuid.v4(),
      storeId: storeId,
      visitId: visitId,
      filePath: file.path,
      createdAt: DateTime.now(),
    );

    await _photoRepository.insertPhoto(photo);
    return photo;
  }
}
