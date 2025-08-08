import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// 写真撮影・選択のサービスクラス
///
/// 使用例:
/// ```dart
/// final photoService = PhotoService();
/// final file = await photoService.takePhotoFromCamera();
/// ```
///
/// 制限事項:
/// - 画像品質は80%に固定
/// - サポート形式: JPEG, PNG
/// - 最大ファイルサイズ: プラットフォーム制限に依存
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
        return await _validateAndProcessImage(image);
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw const PhotoServiceException('カメラへのアクセスが拒否されました');
      } else if (e.code == 'permission_denied') {
        throw const PhotoServiceException('カメラの権限が許可されていません');
      } else if (e.code == 'permission_permanently_denied') {
        throw const PhotoServiceException(
            'カメラの権限が永続的に拒否されています。設定画面から権限を有効にしてください');
      }
      throw PhotoServiceException('カメラでの撮影に失敗しました: ${e.message}');
    } catch (e) {
      throw PhotoServiceException('予期しないエラーが発生しました: $e');
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
        return await _validateAndProcessImage(image);
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw const PhotoServiceException('フォトライブラリへのアクセスが拒否されました');
      } else if (e.code == 'permission_denied') {
        throw const PhotoServiceException('フォトライブラリの権限が許可されていません');
      }
      throw PhotoServiceException('ギャラリーからの選択に失敗しました: ${e.message}');
    } catch (e) {
      throw PhotoServiceException('予期しないエラーが発生しました: $e');
    }
  }

  /// 写真選択方法を選択するダイアログの選択肢
  Future<File?> showPhotoSelectionDialog({
    required bool allowCamera,
    required bool allowGallery,
  }) async {
    if (!allowCamera && !allowGallery) {
      throw const PhotoServiceException('カメラとギャラリーの両方が無効です');
    }

    if (allowCamera && !allowGallery) {
      return takePhotoFromCamera();
    }

    if (allowGallery && !allowCamera) {
      return pickPhotoFromGallery();
    }

    // 両方が有効な場合は、呼び出し側でダイアログを表示する必要がある
    throw const PhotoServiceException('写真選択方法を指定してください');
  }

  /// 画像ファイルの検証と処理
  Future<File> _validateAndProcessImage(XFile image) async {
    final file = File(image.path);

    // ファイルサイズ制限チェック（5MB）
    final fileSize = await file.length();
    const maxFileSize = 5 * 1024 * 1024; // 5MB
    if (fileSize > maxFileSize) {
      throw const PhotoServiceException('ファイルサイズが大きすぎます（5MB以下にしてください）');
    }

    // 許可される拡張子チェック
    final allowedExtensions = ['.jpg', '.jpeg', '.png'];
    final fileName = image.path.toLowerCase();
    if (!allowedExtensions.any((ext) => fileName.endsWith(ext))) {
      throw const PhotoServiceException('サポートされていないファイル形式です（JPEG, PNG のみ対応）');
    }

    return file;
  }
}

/// PhotoService専用の例外クラス
class PhotoServiceException implements Exception {
  final String message;

  const PhotoServiceException(this.message);

  @override
  String toString() => 'PhotoServiceException: $message';
}
