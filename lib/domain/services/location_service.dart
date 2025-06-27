import 'package:flutter/foundation.dart';
import '../entities/location.dart';

/// 位置情報サービスのインターフェース
abstract class LocationService {
  /// 現在位置を取得
  Future<Location> getCurrentLocation();

  /// 位置情報サービスが有効かチェック
  Future<bool> isLocationServiceEnabled();

  /// 位置情報権限があるかチェック
  Future<bool> hasLocationPermission();

  /// 位置情報権限をリクエスト
  Future<bool> requestLocationPermission();
}

/// LocationServiceのテスト専用実装
///
/// 注意: この実装は開発・テスト用のダミー実装です。
/// 本番環境では実際のGeolocatorLocationServiceを使用してください。
/// TDD開発プロセスの履歴として残されています。
@visibleForTesting
class LocationServiceImpl implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    // 🟢 GREEN: 仮実装でテストを通す
    // 東京駅の座標を返す
    return Location(
      latitude: 35.6762,
      longitude: 139.6503,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
  }

  @override
  Future<bool> hasLocationPermission() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
  }

  @override
  Future<bool> requestLocationPermission() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
  }
}
