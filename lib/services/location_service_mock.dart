import 'dart:io';
import 'dart:math';
import 'location_service.dart';

/// Issue #43: 包括的エラーシミュレーション機能
/// LocationServiceの高度なモッククラス
class LocationServiceMock extends LocationService {
  static final Random _random = Random();

  @override
  Future<LocationServiceResult> getCurrentPosition() async {
    // 10種類のエラーパターンシミュレーション
    final errorPattern = Platform.environment['ERROR_SIMULATION_PATTERN'];

    switch (errorPattern) {
      case 'gps_weak':
        return _simulateGpsWeakSignal();
      case 'multipath':
        return _simulateMultipathEnvironment();
      case 'indoor':
        return _simulateIndoorLimitation();
      case 'battery_optimization':
        return _simulateBatteryOptimization();
      case 'permission_timing':
        return _simulatePermissionChangeOnTiming();
      case 'network_unstable':
        return _simulateUnstableNetworkConnection();
      case 'high_speed_movement':
        return _simulateHighSpeedMovement();
      case 'app_switching':
        return _simulateAppSwitchingStatePreservation();
      case 'os_version_difference':
        return _simulateOsVersionPerformanceDifference();
      case 'memory_shortage':
        return _simulateMemoryShortage();
      default:
        return super.getCurrentPosition();
    }
  }

  /// パターン1: GPS信号弱化シミュレーション
  Future<LocationServiceResult> _simulateGpsWeakSignal() async {
    await Future.delayed(const Duration(seconds: 3)); // GPS取得遅延

    final signalStrength = _random.nextDouble();
    if (signalStrength < 0.3) {
      return LocationServiceResult.failure('GPS信号が弱すぎます。屋外の開けた場所で再試行してください。');
    } else if (signalStrength < 0.6) {
      return LocationServiceResult.failure('GPS信号が不安定です。位置情報の精度が低下しています。');
    } else {
      // 低精度の座標を返す
      return LocationServiceResult.success(
        lat: 35.6762 + (_random.nextDouble() - 0.5) * 0.01, // ±500m程度の誤差
        lng: 139.6503 + (_random.nextDouble() - 0.5) * 0.01,
      );
    }
  }

  /// パターン2: 都市部マルチパス環境シミュレーション
  Future<LocationServiceResult> _simulateMultipathEnvironment() async {
    await Future.delayed(const Duration(seconds: 2));

    final buildingDensity = _random.nextDouble();
    if (buildingDensity > 0.7) {
      return LocationServiceResult.failure(
          'マルチパス干渉により位置情報が不安定です。高層ビル群を避けて再試行してください。');
    } else {
      // 座標が不安定にジャンプする
      final jumpDistance = _random.nextDouble() * 0.005; // 最大250m程度のジャンプ
      return LocationServiceResult.success(
        lat: 35.6762 + jumpDistance,
        lng: 139.6503 + jumpDistance,
      );
    }
  }

  /// パターン3: 地下・屋内GPS制限シミュレーション
  Future<LocationServiceResult> _simulateIndoorLimitation() async {
    await Future.delayed(const Duration(seconds: 5)); // 長時間の取得試行

    final indoorDepth = _random.nextDouble();
    if (indoorDepth > 0.8) {
      return LocationServiceResult.failure(
          '屋内環境のためGPS取得できません。Wi-Fi位置情報に切り替えることを推奨します。');
    } else if (indoorDepth > 0.5) {
      return LocationServiceResult.failure('GPS信号が届きません。屋外に移動してから再試行してください。');
    } else {
      // 最後に記録された位置を返す（古い位置情報）
      return LocationServiceResult.success(
        lat: 35.6762,
        lng: 139.6503,
      );
    }
  }

  /// パターン4: バッテリー最適化による制限シミュレーション
  Future<LocationServiceResult> _simulateBatteryOptimization() async {
    final batteryLevel = _random.nextDouble();

    if (batteryLevel < 0.2) {
      return LocationServiceResult.failure('バッテリー残量が少ないため、位置情報機能が制限されています。');
    } else if (batteryLevel < 0.5) {
      await Future.delayed(const Duration(seconds: 8)); // 省電力モードによる遅延
      return LocationServiceResult.failure('省電力モードにより位置情報の更新頻度が制限されています。');
    } else {
      await Future.delayed(const Duration(seconds: 4));
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン5: 権限変更タイミングシミュレーション
  Future<LocationServiceResult> _simulatePermissionChangeOnTiming() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final permissionTiming = _random.nextDouble();
    if (permissionTiming < 0.3) {
      return LocationServiceResult.failure(
          '位置情報の権限が実行中に取り消されました。設定から権限を確認してください。');
    } else {
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン6: 不安定ネットワーク接続シミュレーション
  Future<LocationServiceResult> _simulateUnstableNetworkConnection() async {
    final networkStability = _random.nextDouble();

    if (networkStability < 0.4) {
      await Future.delayed(const Duration(seconds: 10));
      return LocationServiceResult.failure('ネットワーク接続が不安定です。A-GPS情報の取得に失敗しました。');
    } else if (networkStability < 0.7) {
      await Future.delayed(const Duration(seconds: 6));
      return LocationServiceResult.failure('ネットワーク遅延により位置情報の取得に時間がかかっています。');
    } else {
      await Future.delayed(const Duration(seconds: 2));
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン7: 高速移動中の位置追跡シミュレーション
  Future<LocationServiceResult> _simulateHighSpeedMovement() async {
    final movementSpeed = _random.nextDouble();

    if (movementSpeed > 0.8) {
      return LocationServiceResult.failure('高速移動中のため位置情報の精度が著しく低下しています。');
    } else if (movementSpeed > 0.5) {
      // 移動による座標の大きな変化
      return LocationServiceResult.success(
        lat: 35.6762 + (_random.nextDouble() - 0.5) * 0.1, // ±5km程度
        lng: 139.6503 + (_random.nextDouble() - 0.5) * 0.1,
      );
    } else {
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン8: アプリ切り替え状態保持シミュレーション
  Future<LocationServiceResult> _simulateAppSwitchingStatePreservation() async {
    final appSwitchFrequency = _random.nextDouble();

    if (appSwitchFrequency > 0.6) {
      return LocationServiceResult.failure(
          'アプリがバックグラウンドに移行したため、位置情報の更新が停止されました。');
    } else {
      await Future.delayed(const Duration(seconds: 1));
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン9: OS版数によるパフォーマンス差シミュレーション
  Future<LocationServiceResult>
      _simulateOsVersionPerformanceDifference() async {
    final osVersion = _random.nextDouble();

    if (osVersion < 0.3) {
      await Future.delayed(const Duration(seconds: 8));
      return LocationServiceResult.failure('古いOSバージョンのため位置情報サービスの性能が制限されています。');
    } else if (osVersion < 0.6) {
      await Future.delayed(const Duration(seconds: 4));
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    } else {
      await Future.delayed(const Duration(seconds: 1));
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  /// パターン10: メモリ不足シミュレーション
  Future<LocationServiceResult> _simulateMemoryShortage() async {
    final memoryPressure = _random.nextDouble();

    if (memoryPressure > 0.8) {
      return LocationServiceResult.failure('メモリ不足により位置情報サービスが強制終了されました。');
    } else if (memoryPressure > 0.5) {
      await Future.delayed(const Duration(seconds: 6));
      return LocationServiceResult.failure('メモリ使用量が高いため、位置情報の処理が遅延しています。');
    } else {
      return LocationServiceResult.success(lat: 35.6762, lng: 139.6503);
    }
  }

  @override
  Future<PermissionResult> checkLocationPermission() async {
    // PermissionResultのモック実装も提供
    final permissionPattern =
        Platform.environment['PERMISSION_SIMULATION_PATTERN'];

    switch (permissionPattern) {
      case 'timing_change':
        await Future.delayed(const Duration(seconds: 1));
        return PermissionResult.denied('権限チェック中に権限が変更されました');
      case 'os_dialog_delay':
        await Future.delayed(const Duration(seconds: 5));
        return PermissionResult.granted();
      default:
        return super.checkLocationPermission();
    }
  }
}
