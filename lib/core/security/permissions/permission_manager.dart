import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_settings/app_settings.dart';

import '../../exceptions/infrastructure/security_exception.dart';
import '../logging/secure_logger.dart';

/// 権限の種類
enum PermissionType {
  location,
  camera,
  storage,
  notification,
}

/// 権限の状態
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

/// 権限結果
class PermissionResult {
  final PermissionType type;
  final PermissionStatus status;
  final String? message;
  final DateTime timestamp;

  const PermissionResult({
    required this.type,
    required this.status,
    this.message,
    required this.timestamp,
  });

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;
  bool get isRestricted => status == PermissionStatus.restricted;

  @override
  String toString() {
    return 'PermissionResult(type: $type, status: $status, message: $message)';
  }
}

/// 権限リクエストのコールバック
typedef PermissionCallback = void Function(PermissionResult result);

/// 権限管理マネージャー
///
/// アプリケーションに必要な各種権限の管理を行います。
class PermissionManager with SecureLogging {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final Map<PermissionType, PermissionStatus> _permissionCache = {};
  final List<PermissionCallback> _callbacks = [];
  Timer? _backgroundCheckTimer;
  bool _isMonitoring = false;

  /// 権限の状態変更をリッスンするコールバックを追加
  void addCallback(PermissionCallback callback) {
    _callbacks.add(callback);
  }

  /// 権限の状態変更をリッスンするコールバックを削除
  void removeCallback(PermissionCallback callback) {
    _callbacks.remove(callback);
  }

  /// バックグラウンド権限監視を開始
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _backgroundCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAllPermissions(),
    );

    logInfo('権限監視を開始しました');
  }

  /// バックグラウンド権限監視を停止
  void stopMonitoring() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer = null;
    _isMonitoring = false;

    logInfo('権限監視を停止しました');
  }

  /// 位置情報権限の確認
  Future<PermissionResult> checkLocationPermission() async {
    try {
      logDebug('位置情報権限の確認を開始');

      final permission = await Geolocator.checkPermission();
      final status = _mapLocationPermission(permission);

      final result = PermissionResult(
        type: PermissionType.location,
        status: status,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      logInfo('位置情報権限確認完了', data: {'status': status.name});

      return result;
    } catch (e, stackTrace) {
      logError('位置情報権限の確認に失敗', error: e, stackTrace: stackTrace);

      return PermissionResult(
        type: PermissionType.location,
        status: PermissionStatus.unknown,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// 位置情報権限のリクエスト
  Future<PermissionResult> requestLocationPermission() async {
    try {
      logDebug('位置情報権限のリクエストを開始');

      // まず現在の状態を確認
      final currentResult = await checkLocationPermission();
      if (currentResult.isGranted) {
        logInfo('位置情報権限は既に許可されています');
        return currentResult;
      }

      if (currentResult.isPermanentlyDenied) {
        logWarning('位置情報権限が永続的に拒否されています');
        return PermissionResult(
          type: PermissionType.location,
          status: PermissionStatus.permanentlyDenied,
          message: '設定アプリから権限を有効にしてください',
          timestamp: DateTime.now(),
        );
      }

      // 権限をリクエスト
      final permission = await Geolocator.requestPermission();
      final status = _mapLocationPermission(permission);

      final result = PermissionResult(
        type: PermissionType.location,
        status: status,
        message: status == PermissionStatus.denied ? '位置情報権限が拒否されました' : null,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      _notifyCallbacks(result);

      logInfo('位置情報権限リクエスト完了', data: {'status': status.name});

      return result;
    } catch (e, stackTrace) {
      logError('位置情報権限のリクエストに失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        '位置情報権限の取得に失敗しました',
        context: 'Permission request',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// カメラ権限の確認
  Future<PermissionResult> checkCameraPermission() async {
    try {
      logDebug('カメラ権限の確認を開始');

      // ImagePickerを使用してカメラアクセスを試行
      // 実際の実装では、permission_handlerパッケージを使用することを推奨
      final status = await _testCameraAccess();

      final result = PermissionResult(
        type: PermissionType.camera,
        status: status,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      logInfo('カメラ権限確認完了', data: {'status': status.name});

      return result;
    } catch (e, stackTrace) {
      logError('カメラ権限の確認に失敗', error: e, stackTrace: stackTrace);

      return PermissionResult(
        type: PermissionType.camera,
        status: PermissionStatus.unknown,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// カメラ権限のリクエスト
  Future<PermissionResult> requestCameraPermission() async {
    try {
      logDebug('カメラ権限のリクエストを開始');

      // 現在の状態を確認
      final currentResult = await checkCameraPermission();
      if (currentResult.isGranted) {
        logInfo('カメラ権限は既に許可されています');
        return currentResult;
      }

      // ImagePickerでカメラアクセスを試行（権限リクエストを兼ねる）
      final picker = ImagePicker();
      try {
        await picker.pickImage(source: ImageSource.camera);

        final result = PermissionResult(
          type: PermissionType.camera,
          status: PermissionStatus.granted,
          timestamp: DateTime.now(),
        );

        _updatePermissionCache(result);
        _notifyCallbacks(result);

        logInfo('カメラ権限リクエスト完了', data: {'status': 'granted'});
        return result;
      } catch (e) {
        // ユーザーがキャンセルした場合やアクセスが拒否された場合
        final result = PermissionResult(
          type: PermissionType.camera,
          status: PermissionStatus.denied,
          message: 'カメラアクセスが拒否されました',
          timestamp: DateTime.now(),
        );

        _updatePermissionCache(result);
        _notifyCallbacks(result);

        logWarning('カメラ権限が拒否されました', error: e);
        return result;
      }
    } catch (e, stackTrace) {
      logError('カメラ権限のリクエストに失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'カメラ権限の取得に失敗しました',
        context: 'Camera permission request',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ストレージ権限の確認
  Future<PermissionResult> checkStoragePermission() async {
    try {
      logDebug('ストレージ権限の確認を開始');

      // Android 10以降ではスコープストレージが適用されるため、
      // 基本的には特別な権限は不要
      final status = PermissionStatus.granted;

      final result = PermissionResult(
        type: PermissionType.storage,
        status: status,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      logInfo('ストレージ権限確認完了', data: {'status': status.name});

      return result;
    } catch (e, stackTrace) {
      logError('ストレージ権限の確認に失敗', error: e, stackTrace: stackTrace);

      return PermissionResult(
        type: PermissionType.storage,
        status: PermissionStatus.unknown,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// 複数の権限を一括確認
  Future<Map<PermissionType, PermissionResult>> checkMultiplePermissions(
    List<PermissionType> permissions,
  ) async {
    final results = <PermissionType, PermissionResult>{};

    for (final permission in permissions) {
      switch (permission) {
        case PermissionType.location:
          results[permission] = await checkLocationPermission();
          break;
        case PermissionType.camera:
          results[permission] = await checkCameraPermission();
          break;
        case PermissionType.storage:
          results[permission] = await checkStoragePermission();
          break;
        case PermissionType.notification:
          // 通知権限の実装は省略
          results[permission] = PermissionResult(
            type: PermissionType.notification,
            status: PermissionStatus.granted,
            timestamp: DateTime.now(),
          );
          break;
      }
    }

    logInfo('複数権限確認完了', data: {
      'permissions': permissions.map((p) => p.name).toList(),
      'results': results.map((k, v) => MapEntry(k.name, v.status.name)),
    });

    return results;
  }

  /// 複数の権限を一括リクエスト
  Future<Map<PermissionType, PermissionResult>> requestMultiplePermissions(
    List<PermissionType> permissions,
  ) async {
    final results = <PermissionType, PermissionResult>{};

    for (final permission in permissions) {
      switch (permission) {
        case PermissionType.location:
          results[permission] = await requestLocationPermission();
          break;
        case PermissionType.camera:
          results[permission] = await requestCameraPermission();
          break;
        case PermissionType.storage:
          results[permission] = await checkStoragePermission();
          break;
        case PermissionType.notification:
          // 通知権限の実装は省略
          results[permission] = PermissionResult(
            type: PermissionType.notification,
            status: PermissionStatus.granted,
            timestamp: DateTime.now(),
          );
          break;
      }
    }

    logInfo('複数権限リクエスト完了', data: {
      'permissions': permissions.map((p) => p.name).toList(),
      'results': results.map((k, v) => MapEntry(k.name, v.status.name)),
    });

    return results;
  }

  /// アプリ設定画面を開く
  Future<void> openAppSettings() async {
    try {
      logInfo('アプリ設定画面を開きます');
      await AppSettings.openAppSettings();
    } catch (e, stackTrace) {
      logError('アプリ設定画面を開くのに失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'アプリ設定画面を開けませんでした',
        context: 'App settings',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 権限のキャッシュを取得
  PermissionStatus? getCachedPermissionStatus(PermissionType type) {
    return _permissionCache[type];
  }

  /// 権限のキャッシュをクリア
  void clearPermissionCache() {
    _permissionCache.clear();
    logInfo('権限キャッシュをクリアしました');
  }

  /// Geolocator権限を内部形式にマップ
  PermissionStatus _mapLocationPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PermissionStatus.granted;
      case LocationPermission.denied:
        return PermissionStatus.denied;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return PermissionStatus.unknown;
    }
  }

  /// カメラアクセスのテスト
  Future<PermissionStatus> _testCameraAccess() async {
    try {
      final picker = ImagePicker();
      await picker.pickImage(source: ImageSource.camera);
      return PermissionStatus.granted;
    } catch (e) {
      // エラーの種類によって状態を判定
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') ||
          errorMessage.contains('access')) {
        return PermissionStatus.denied;
      }
      return PermissionStatus.unknown;
    }
  }

  /// 権限キャッシュを更新
  void _updatePermissionCache(PermissionResult result) {
    _permissionCache[result.type] = result.status;
  }

  /// コールバックに通知
  void _notifyCallbacks(PermissionResult result) {
    for (final callback in _callbacks) {
      try {
        callback(result);
      } catch (e) {
        logError('権限コールバック実行に失敗', error: e);
      }
    }
  }

  /// 全権限をバックグラウンドチェック
  Future<void> _checkAllPermissions() async {
    try {
      final permissions = [
        PermissionType.location,
        PermissionType.camera,
        PermissionType.storage,
      ];

      await checkMultiplePermissions(permissions);
    } catch (e) {
      logError('バックグラウンド権限チェックに失敗', error: e);
    }
  }

  /// リソースの解放
  void dispose() {
    stopMonitoring();
    _callbacks.clear();
    _permissionCache.clear();
    logInfo('PermissionManagerを解放しました');
  }
}
