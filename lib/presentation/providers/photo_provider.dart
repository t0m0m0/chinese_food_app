import 'package:flutter/foundation.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/usecases/pick_image_usecase.dart';

/// 写真データの状態管理を行うProvider
///
/// 写真の読み込み、追加、削除などの操作と状態管理を担当し、
/// Clean ArchitectureのPresentation層でドメイン層のRepositoryと連携する
class PhotoProvider extends ChangeNotifier {
  final PhotoRepository repository;
  final PickImageUsecase pickImageUsecase;

  /// 写真リスト
  List<Photo> _photos = [];

  /// ローディング状態
  bool _isLoading = false;

  /// エラーメッセージ
  String? _error;

  PhotoProvider({
    required this.repository,
    required this.pickImageUsecase,
  });

  // Getters
  List<Photo> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 店舗IDで写真を読み込む
  Future<void> loadPhotosByStoreId(String storeId) async {
    _setLoading(true);
    _clearError();

    try {
      _photos = await repository.getPhotosByStoreId(storeId);
      notifyListeners();
    } catch (e) {
      _setError('写真の読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 訪問記録IDで写真を読み込む
  Future<void> loadPhotosByVisitId(String visitId) async {
    _setLoading(true);
    _clearError();

    try {
      _photos = await repository.getPhotosByVisitId(visitId);
      notifyListeners();
    } catch (e) {
      _setError('写真の読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 全ての写真を読み込む
  Future<void> loadAllPhotos() async {
    _setLoading(true);
    _clearError();

    try {
      _photos = await repository.getAllPhotos();
      notifyListeners();
    } catch (e) {
      _setError('写真の読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// カメラから写真を追加
  Future<void> addPhotoFromCamera(String storeId, {String? visitId}) async {
    _setLoading(true);
    _clearError();

    try {
      final photo =
          await pickImageUsecase.pickFromCamera(storeId, visitId: visitId);
      _photos.add(photo);
      notifyListeners();
    } catch (e) {
      _setError('写真の追加に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// ギャラリーから写真を追加
  Future<void> addPhotoFromGallery(String storeId, {String? visitId}) async {
    _setLoading(true);
    _clearError();

    try {
      final photo =
          await pickImageUsecase.pickFromGallery(storeId, visitId: visitId);
      _photos.add(photo);
      notifyListeners();
    } catch (e) {
      _setError('写真の追加に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 写真を削除
  Future<void> deletePhoto(String photoId) async {
    _setLoading(true);
    _clearError();

    try {
      await repository.deletePhoto(photoId);
      _photos.removeWhere((photo) => photo.id == photoId);
      notifyListeners();
    } catch (e) {
      _setError('写真の削除に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
  }

  /// ローディング状態を設定（内部用）
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// エラーを設定（内部用）
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// エラーをクリア（内部用）
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// テスト用のエラー設定メソッド
  @visibleForTesting
  void setError(String error) {
    _setError(error);
  }
}
