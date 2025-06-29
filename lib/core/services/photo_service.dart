import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 写真撮影・選択のサービスクラス
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// カメラで写真を撮影
  Future<File?> takePhotoFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80, // 品質を80%に設定（ファイルサイズ最適化）
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw PhotoServiceException('カメラでの撮影に失敗しました: $e');
    }
  }

  /// ギャラリーから写真を選択
  Future<File?> pickPhotoFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // 品質を80%に設定（ファイルサイズ最適化）
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw PhotoServiceException('ギャラリーからの選択に失敗しました: $e');
    }
  }

  /// 写真選択方法を選択するダイアログの選択肢
  Future<File?> showPhotoSelectionDialog({
    required bool allowCamera,
    required bool allowGallery,
  }) async {
    if (!allowCamera && !allowGallery) {
      throw PhotoServiceException('カメラとギャラリーの両方が無効です');
    }

    if (allowCamera && !allowGallery) {
      return takePhotoFromCamera();
    }

    if (allowGallery && !allowCamera) {
      return pickPhotoFromGallery();
    }

    // 両方が有効な場合は、呼び出し側でダイアログを表示する必要がある
    throw PhotoServiceException('写真選択方法を指定してください');
  }
}

/// PhotoService専用の例外クラス
class PhotoServiceException implements Exception {
  final String message;

  const PhotoServiceException(this.message);

  @override
  String toString() => 'PhotoServiceException: $message';
}
