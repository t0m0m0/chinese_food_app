import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math' as math;
import '../entities/location.dart';
import '../entities/location_performance_metrics.dart';
import '../../core/constants/location_constants.dart';
import 'location_service.dart';

/// 最適化された位置情報サービス
///
/// 機能:
/// - 位置情報キャッシュ
/// - バッテリー最適化
/// - 非同期処理（StreamController）
/// - パフォーマンス監視
/// - Isolateでの重い処理
class OptimizedLocationService implements LocationService {
  final LocationService _locationService;

  // キャッシュ関連
  Location? _cachedLocation;
  DateTime? _cacheTimestamp;
  final Duration _cacheExpirationDuration;

  // バッテリー最適化
  final double _batteryLevel;
  bool get _isBatteryOptimized =>
      _batteryLevel < LocationConstants.lowBatteryThreshold;

  // StreamController for async processing
  late final StreamController<Location> _locationStreamController;
  late final StreamController<LocationException> _errorStreamController;
  Timer? _periodicTimer;

  // パフォーマンス監視
  final List<Duration> _responseTimes = [];
  final List<bool> _cacheHitHistory = [];
  final List<String> _errorHistory = [];
  int _totalRequests = 0;
  int _cacheHits = 0;

  // Isolate処理用
  ReceivePort? _isolateReceivePort;
  Isolate? _isolate;

  OptimizedLocationService({
    required LocationService locationService,
    Duration? cacheExpirationDuration,
    double batteryLevel = 1.0,
  })  : _locationService = locationService,
        _cacheExpirationDuration =
            cacheExpirationDuration ?? LocationConstants.defaultCacheExpiration,
        _batteryLevel = batteryLevel,
        _locationStreamController = StreamController<Location>.broadcast(),
        _errorStreamController =
            StreamController<LocationException>.broadcast() {
    _initializeIsolate();
    _startPeriodicLocationUpdates();
  }

  /// Isolateの初期化
  Future<void> _initializeIsolate() async {
    try {
      _isolateReceivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _isolateReceivePort!.sendPort,
      );

      _isolateReceivePort!.listen((data) {
        if (data is SendPort) {
          developer.log('Isolate initialized successfully',
              name: 'OptimizedLocationService');
        } else if (data is Map<String, dynamic>) {
          // Isolateからの処理結果を受信
          _handleIsolateResult(data);
        }
      });
    } catch (e) {
      developer.log('Failed to initialize isolate: $e',
          name: 'OptimizedLocationService');
    }
  }

  /// Isolateのエントリーポイント
  static void _isolateEntryPoint(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((data) {
      if (data is Map<String, dynamic>) {
        // 重い計算処理をここで実行
        final result = _performHeavyCalculation(data);
        mainSendPort.send(result);
      }
    });
  }

  /// Isolateでの重い計算処理
  static Map<String, dynamic> _performHeavyCalculation(
      Map<String, dynamic> data) {
    // 位置情報の距離計算などの重い処理をシミュレート
    final lat1 = data['lat1'] as double;
    final lng1 = data['lng1'] as double;
    final lat2 = data['lat2'] as double;
    final lng2 = data['lng2'] as double;

    final distance = _calculateDistance(lat1, lng1, lat2, lng2);

    return {
      'distance': distance,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 2点間の距離を計算（Haversine式）
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth radius in meters

    final double lat1Rad = lat1 * math.pi / 180;
    final double lat2Rad = lat2 * math.pi / 180;
    final double deltaLatRad = (lat2 - lat1) * math.pi / 180;
    final double deltaLngRad = (lng2 - lng1) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Isolateからの結果を処理
  void _handleIsolateResult(Map<String, dynamic> result) {
    developer.log('Received result from isolate: $result',
        name: 'OptimizedLocationService');
  }

  /// 定期的な位置情報更新の開始
  void _startPeriodicLocationUpdates() {
    final interval = _isBatteryOptimized
        ? LocationConstants.batteryOptimizedInterval
        : LocationConstants.normalInterval;

    _periodicTimer = Timer.periodic(interval, (_) async {
      try {
        final location = await getCurrentLocation();
        _locationStreamController.add(location);
      } catch (e) {
        if (e is LocationException) {
          _errorStreamController.add(e);
        } else {
          _errorStreamController.add(LocationException(
            'Periodic location update failed: $e',
            LocationExceptionType.locationUnavailable,
          ));
        }
      }
    });
  }

  @override
  Future<Location> getCurrentLocation() async {
    final stopwatch = Stopwatch()..start();
    _totalRequests++;

    try {
      // キャッシュチェック
      if (_isCacheValid()) {
        stopwatch.stop();
        _recordCacheHit(stopwatch.elapsed);
        developer.log('Location served from cache',
            name: 'OptimizedLocationService');
        return _cachedLocation!;
      }

      // バッテリー最適化の考慮
      final timeout = _isBatteryOptimized
          ? LocationConstants.batteryOptimizedTimeout
          : LocationConstants.defaultLocationTimeout;

      developer.log(
          'Requesting new location (battery optimized: $_isBatteryOptimized)',
          name: 'OptimizedLocationService');

      // 位置情報取得（タイムアウト付き）
      final location =
          await _locationService.getCurrentLocation().timeout(timeout);

      // キャッシュ更新
      _updateCache(location);

      stopwatch.stop();
      _recordResponseTime(stopwatch.elapsed, false);

      developer.log(
          'New location obtained: ${location.latitude}, ${location.longitude}',
          name: 'OptimizedLocationService');

      // ストリームに新しい位置情報を送信
      if (!_locationStreamController.isClosed) {
        _locationStreamController.add(location);
      }

      return location;
    } catch (e) {
      stopwatch.stop();
      _recordError(e.toString(), stopwatch.elapsed);

      if (e is LocationException) {
        rethrow;
      } else if (e is TimeoutException) {
        throw LocationException(
          'Location request timed out',
          LocationExceptionType.timeout,
        );
      } else {
        throw LocationException(
          'Failed to get location: $e',
          LocationExceptionType.locationUnavailable,
        );
      }
    }
  }

  /// キャッシュが有効かどうかをチェック
  bool _isCacheValid() {
    if (_cachedLocation == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);

    // 時間による期限切れチェック
    if (cacheAge > _cacheExpirationDuration) {
      developer.log('Cache expired (age: ${cacheAge.inMinutes} minutes)',
          name: 'OptimizedLocationService');
      return false;
    }

    return true;
  }

  /// キャッシュを更新
  void _updateCache(Location location) {
    _cachedLocation = location;
    _cacheTimestamp = DateTime.now();
  }

  /// キャッシュをクリア
  Future<void> clearCache() async {
    _cachedLocation = null;
    _cacheTimestamp = null;
    developer.log('Cache cleared', name: 'OptimizedLocationService');
  }

  /// 位置情報ストリームを取得
  Stream<Location> getLocationStream() {
    return _locationStreamController.stream;
  }

  /// エラーストリームを取得
  Stream<LocationException> getErrorStream() {
    return _errorStreamController.stream;
  }

  /// レスポンス時間を記録
  void _recordResponseTime(Duration duration, bool isFromCache) {
    _responseTimes.add(duration);
    _cacheHitHistory.add(isFromCache);

    // 履歴サイズを制限
    if (_responseTimes.length >
        LocationConstants.performanceMetricsWindowSize) {
      _responseTimes.removeAt(0);
      _cacheHitHistory.removeAt(0);
    }
  }

  /// キャッシュヒットを記録
  void _recordCacheHit(Duration duration) {
    _cacheHits++;
    _recordResponseTime(duration, true);
  }

  /// エラーを記録
  void _recordError(String error, Duration duration) {
    _errorHistory.add(error);
    _recordResponseTime(duration, false);

    // エラー履歴サイズを制限
    if (_errorHistory.length > LocationConstants.performanceMetricsWindowSize) {
      _errorHistory.removeAt(0);
    }
  }

  /// パフォーマンスメトリクスを取得
  LocationPerformanceMetrics getPerformanceMetrics() {
    final lastResponseTime =
        _responseTimes.isNotEmpty ? _responseTimes.last : Duration.zero;

    final averageResponseTime = _responseTimes.isNotEmpty
        ? Duration(
            milliseconds: (_responseTimes
                        .map((d) => d.inMilliseconds)
                        .reduce((a, b) => a + b) /
                    _responseTimes.length)
                .round())
        : Duration.zero;

    final cacheHitRate = _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0;

    final errorRate =
        _totalRequests > 0 ? _errorHistory.length / _totalRequests : 0.0;

    final cpuUsage = _estimateCpuUsage();
    final memoryUsage = _estimateMemoryUsage();

    return LocationPerformanceMetrics(
      lastResponseTime: lastResponseTime,
      averageResponseTime: averageResponseTime,
      totalRequests: _totalRequests,
      cacheHits: _cacheHits,
      cacheHitRate: cacheHitRate,
      lastError: _errorHistory.isNotEmpty ? _errorHistory.last : null,
      errorRate: errorRate,
      cpuUsage: cpuUsage,
      memoryUsage: memoryUsage,
      isBatteryOptimized: _isBatteryOptimized,
    );
  }

  /// CPU使用率の推定
  double _estimateCpuUsage() {
    // 簡単な推定：平均レスポンス時間とリクエスト頻度から算出
    if (_responseTimes.isEmpty) return 0.0;

    final avgResponseMs =
        _responseTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            _responseTimes.length;

    // レスポンス時間が長いほどCPU使用率が高いと仮定
    return (avgResponseMs / 2000).clamp(0.0, 1.0);
  }

  /// メモリ使用量の推定
  double _estimateMemoryUsage() {
    // 簡単な推定：キャッシュサイズと履歴データから算出
    double usage = 0.0;

    if (_cachedLocation != null) usage += 1.0; // キャッシュされた位置情報
    usage += _responseTimes.length * 0.1; // レスポンス時間履歴
    usage += _errorHistory.length * 0.2; // エラー履歴

    return usage;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  @override
  Future<bool> hasLocationPermission() async {
    return await _locationService.hasLocationPermission();
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await _locationService.requestLocationPermission();
  }

  /// リソースの解放
  void dispose() {
    _periodicTimer?.cancel();
    _locationStreamController.close();
    _errorStreamController.close();

    // Isolateの終了
    _isolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();

    developer.log('OptimizedLocationService disposed',
        name: 'OptimizedLocationService');
  }
}
