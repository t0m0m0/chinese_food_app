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

