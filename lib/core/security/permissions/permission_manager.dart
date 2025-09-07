import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';

import '../security_error_handler.dart';

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

/// 権限の結果
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
  String toString() =>
      'PermissionResult(type: $type, status: $status, message: $message)';
}

/// 権限状態変更時のコールバック関数の型定義
typedef PermissionCallback = void Function(PermissionResult result);

/// 権限管理マネージャー（MVP用に簡素化）
///
/// アプリケーションに必要な基本的な権限管理を行います
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final Map<PermissionType, PermissionResult> _permissionCache = {};
  final List<PermissionCallback> _callbacks = [];
  Timer? _backgroundCheckTimer;
  bool _isMonitoring = false;

  /// 権限の状態変更をリッスンするコールバックを追加
  void addCallback(PermissionCallback callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
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
      const Duration(minutes: 5),
      (_) => _checkAllPermissions(),
    );
    developer.log('権限監視を開始しました', name: 'PermissionManager');
  }

  /// バックグラウンド権限監視を停止
  void stopMonitoring() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer = null;
    _isMonitoring = false;
    developer.log('権限監視を停止しました', name: 'PermissionManager');
  }

  /// 位置情報権限の確認
  Future<PermissionResult> checkLocationPermission() async {
    try {
      developer.log('位置情報権限の確認を開始', name: 'PermissionManager');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final result = PermissionResult(
          type: PermissionType.location,
          status: PermissionStatus.denied,
          message: '位置情報サービスが無効です',
          timestamp: DateTime.now(),
        );
        _updatePermissionCache(result);
        return result;
      }

      final permission = await Geolocator.checkPermission();
      final status = _mapLocationPermission(permission);
      final result = PermissionResult(
        type: PermissionType.location,
        status: status,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      developer.log('位置情報権限確認完了: ${status.name}', name: 'PermissionManager');
      return result;
    } catch (e) {
      SecurityErrorHandler.handleSecurityError(
        'checkLocationPermission',
        e,
        SecurityErrorSeverity.error,
        context: 'location permission check',
      );
      // この行は実行されないが、コンパイラエラー回避のため
      rethrow;
    }
  }

  /// 位置情報権限のリクエスト
  Future<PermissionResult> requestLocationPermission() async {
    try {
      developer.log('位置情報権限のリクエストを開始', name: 'PermissionManager');

      // 現在の状態を確認
      final currentResult = await checkLocationPermission();
      if (currentResult.status == PermissionStatus.granted) {
        developer.log('位置情報権限は既に許可されています', name: 'PermissionManager');
        return currentResult;
      }

      if (currentResult.status == PermissionStatus.permanentlyDenied) {
        developer.log('位置情報権限が永続的に拒否されています', name: 'PermissionManager');
        return PermissionResult(
          type: PermissionType.location,
          status: PermissionStatus.permanentlyDenied,
          message: '位置情報権限が永続的に拒否されています。設定から許可してください。',
          timestamp: DateTime.now(),
        );
      }

      // 権限をリクエスト
      final permission = await Geolocator.requestPermission();
      final status = _mapLocationPermission(permission);
      final result = PermissionResult(
        type: PermissionType.location,
        status: status,
        timestamp: DateTime.now(),
      );

      _updatePermissionCache(result);
      _notifyCallbacks(result);
      developer.log('位置情報権限リクエスト完了: ${status.name}', name: 'PermissionManager');

      return result;
    } catch (e) {
      SecurityErrorHandler.handleSecurityError(
        'requestLocationPermission',
        e,
        SecurityErrorSeverity.error,
        context: 'location permission request',
      );
      // この行は実行されないが、コンパイラエラー回避のため
      rethrow;
    }
  }

  /// キャッシュされた権限状態を取得
  PermissionResult? getCachedPermissionStatus(PermissionType type) {
    return _permissionCache[type];
  }

  /// 権限キャッシュをクリア
  void clearPermissionCache() {
    _permissionCache.clear();
    developer.log('権限キャッシュをクリアしました', name: 'PermissionManager');
  }

  /// アプリ設定画面を開く
  Future<void> openAppSettings() async {
    try {
      developer.log('アプリ設定画面を開きます', name: 'PermissionManager');
      await AppSettings.openAppSettings();
    } catch (e) {
      SecurityErrorHandler.handleSecurityError(
        'openAppSettings',
        e,
        SecurityErrorSeverity.error,
        context: 'app settings access',
      );
      // この行は実行されないが、コンパイラエラー回避のため
      rethrow;
    }
  }

  /// 位置情報権限のマッピング
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

  /// 権限キャッシュを更新
  void _updatePermissionCache(PermissionResult result) {
    _permissionCache[result.type] = result;
  }

  /// コールバックに通知
  void _notifyCallbacks(PermissionResult result) {
    for (final callback in _callbacks) {
      try {
        callback(result);
      } catch (e) {
        SecurityErrorHandler.logSecurityWarning(
          'notifyCallbacks',
          e,
          context: 'permission callback execution',
        );
      }
    }
  }

  /// 全権限のチェック（バックグラウンド監視用）
  Future<void> _checkAllPermissions() async {
    try {
      await checkLocationPermission();
    } catch (e) {
      SecurityErrorHandler.logSecurityWarning(
        '_checkAllPermissions',
        e,
        context: 'background permission check',
      );
    }
  }

  /// リソース解放
  void dispose() {
    stopMonitoring();
    _callbacks.clear();
    _permissionCache.clear();
    developer.log('PermissionManagerを解放しました', name: 'PermissionManager');
  }
}
