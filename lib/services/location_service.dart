import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  Future<LocationServiceResult> getCurrentPosition() async {
    try {
      final permission = await _checkLocationPermission();
      if (!permission.isGranted) {
        return LocationServiceResult.failure(
          permission.errorMessage ?? 'Location permission error',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      return LocationServiceResult.success(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      return LocationServiceResult.failure(e.toString());
    }
  }

  Future<GeocodeResult> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return GeocodeResult.failure('住所が見つかりませんでした');
      }

      final placemark = placemarks.first;
      final address = _formatAddress(placemark);

      return GeocodeResult.success(address);
    } catch (e) {
      return GeocodeResult.failure(e.toString());
    }
  }

  Future<GeocodeResult> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        return GeocodeResult.failure('座標が見つかりませんでした');
      }

      final location = locations.first;
      return GeocodeResult.success(
        '${location.latitude}, ${location.longitude}',
        lat: location.latitude,
        lng: location.longitude,
      );
    } catch (e) {
      return GeocodeResult.failure(e.toString());
    }
  }

  Future<_PermissionResult> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _PermissionResult.failure('位置情報サービスが無効です');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _PermissionResult.failure('位置情報の権限が拒否されました');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _PermissionResult.failure(
        '位置情報の権限が永続的に拒否されています。設定から許可してください',
      );
    }

    return _PermissionResult.success();
  }

  String _formatAddress(Placemark placemark) {
    final components = <String>[];

    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      components.add(placemark.subLocality!);
    }
    if (placemark.thoroughfare?.isNotEmpty == true) {
      components.add(placemark.thoroughfare!);
    }
    if (placemark.subThoroughfare?.isNotEmpty == true) {
      components.add(placemark.subThoroughfare!);
    }

    return components.join(' ');
  }
}

class LocationServiceResult {
  final double? lat;
  final double? lng;
  final String? error;
  final bool isSuccess;

  const LocationServiceResult._({
    this.lat,
    this.lng,
    this.error,
    required this.isSuccess,
  });

  factory LocationServiceResult.success({
    required double lat,
    required double lng,
  }) {
    return LocationServiceResult._(
      lat: lat,
      lng: lng,
      isSuccess: true,
    );
  }

  factory LocationServiceResult.failure(String error) {
    return LocationServiceResult._(
      error: error,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'LocationServiceResult.success(lat: $lat, lng: $lng)';
    } else {
      return 'LocationServiceResult.failure($error)';
    }
  }
}

class GeocodeResult {
  final String? address;
  final double? lat;
  final double? lng;
  final String? error;
  final bool isSuccess;

  const GeocodeResult._({
    this.address,
    this.lat,
    this.lng,
    this.error,
    required this.isSuccess,
  });

  factory GeocodeResult.success(
    String address, {
    double? lat,
    double? lng,
  }) {
    return GeocodeResult._(
      address: address,
      lat: lat,
      lng: lng,
      isSuccess: true,
    );
  }

  factory GeocodeResult.failure(String error) {
    return GeocodeResult._(
      error: error,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'GeocodeResult.success($address)';
    } else {
      return 'GeocodeResult.failure($error)';
    }
  }
}

class _PermissionResult {
  final String? errorMessage;
  final bool isGranted;

  const _PermissionResult._({
    this.errorMessage,
    required this.isGranted,
  });

  factory _PermissionResult.success() {
    return const _PermissionResult._(isGranted: true);
  }

  factory _PermissionResult.failure(String errorMessage) {
    return _PermissionResult._(
      errorMessage: errorMessage,
      isGranted: false,
    );
  }
}