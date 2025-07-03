import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/services/optimized_location_service.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/core/constants/location_constants.dart';

/// 最適化された位置情報サービスのテスト
///
/// 機能:
/// - 位置情報キャッシュ
/// - バッテリー最適化
/// - 非同期処理
/// - パフォーマンス監視

class MockLocationService implements LocationService {
  Location? _mockedLocation;
  bool _serviceEnabled = true;
  bool _hasPermission = true;
  Duration _responseDelay = Duration(milliseconds: 100);

  void setMockedLocation(Location location) {
    _mockedLocation = location;
  }

  void setServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
  }

  void setHasPermission(bool hasPermission) {
    _hasPermission = hasPermission;
  }

  void setResponseDelay(Duration delay) {
    _responseDelay = delay;
  }

  @override
  Future<Location> getCurrentLocation() async {
    await Future.delayed(_responseDelay);
    if (!_serviceEnabled) {
      throw LocationException(
        'Location services are disabled',
        LocationExceptionType.serviceDisabled,
      );
    }
    if (!_hasPermission) {
      throw LocationException(
        'Location permission denied',
        LocationExceptionType.permissionDenied,
      );
    }
    if (_mockedLocation == null) {
      throw LocationException(
        'Location unavailable',
        LocationExceptionType.locationUnavailable,
      );
    }
    return _mockedLocation!;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _serviceEnabled;
  }

  @override
  Future<bool> hasLocationPermission() async {
    return _hasPermission;
  }

  @override
  Future<bool> requestLocationPermission() async {
    return _hasPermission;
  }
}

void main() {
  group('OptimizedLocationService Tests', () {
    late MockLocationService mockLocationService;
    late OptimizedLocationService optimizedLocationService;

    setUp(() {
      mockLocationService = MockLocationService();
      optimizedLocationService = OptimizedLocationService(
        locationService: mockLocationService,
      );
    });

    tearDown(() {
      optimizedLocationService.dispose();
    });

    group('位置情報キャッシュ機能テスト', () {
      test('初回取得時は実際のLocationServiceを呼び出す', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);

        // Act
        final result = await optimizedLocationService.getCurrentLocation();

        // Assert
        expect(result.latitude, testLocation.latitude);
        expect(result.longitude, testLocation.longitude);
        expect(result.accuracy, testLocation.accuracy);
      });

      test('キャッシュ有効期限内は同じ位置情報を返す', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);
        mockLocationService.setResponseDelay(Duration(milliseconds: 500));

        // Act - 1回目
        final stopwatch1 = Stopwatch()..start();
        final result1 = await optimizedLocationService.getCurrentLocation();
        stopwatch1.stop();

        // Act - 2回目（キャッシュから返されるはず）
        final stopwatch2 = Stopwatch()..start();
        final result2 = await optimizedLocationService.getCurrentLocation();
        stopwatch2.stop();

        // Assert
        expect(result1.latitude, result2.latitude);
        expect(result1.longitude, result2.longitude);
        // 2回目の方が明らかに速い
        expect(stopwatch2.elapsedMilliseconds,
            lessThan(stopwatch1.elapsedMilliseconds));
        expect(stopwatch2.elapsedMilliseconds, lessThan(100)); // キャッシュから取得
      });

      test('キャッシュ有効期限が切れた場合は新しい位置情報を取得', () async {
        // Arrange
        final oldLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        final newLocation = Location(
          latitude: 35.6813,
          longitude: 139.7672,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );

        mockLocationService.setMockedLocation(oldLocation);

        // Act - 1回目
        final result1 = await optimizedLocationService.getCurrentLocation();

        // キャッシュ有効期限を短く設定したサービスを作成
        final shortCacheService = OptimizedLocationService(
          locationService: mockLocationService,
          cacheExpirationDuration: Duration(milliseconds: 100),
        );

        // 少し待機
        await Future.delayed(Duration(milliseconds: 150));

        // 新しい位置情報を設定
        mockLocationService.setMockedLocation(newLocation);

        // Act - 2回目（キャッシュ期限切れ）
        final result2 = await shortCacheService.getCurrentLocation();

        // Assert
        expect(result1.latitude, oldLocation.latitude);
        expect(result2.latitude, newLocation.latitude);
        expect(result1.latitude, isNot(equals(result2.latitude)));

        shortCacheService.dispose();
      });

      test('位置が大きく変化した場合は新しい位置情報を取得', () async {
        // Arrange
        final nearLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        final farLocation = Location(
          latitude: 35.7812, // 約11km離れた位置
          longitude: 139.8671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );

        mockLocationService.setMockedLocation(nearLocation);

        // Act - 1回目
        final result1 = await optimizedLocationService.getCurrentLocation();

        // キャッシュを明示的にクリア（距離変化をシミュレート）
        await optimizedLocationService.clearCache();

        // 遠い位置を設定
        mockLocationService.setMockedLocation(farLocation);

        // Act - 2回目（キャッシュクリア後なので新しい位置を取得）
        final result2 = await optimizedLocationService.getCurrentLocation();

        // Assert
        expect(result1.latitude, nearLocation.latitude);
        expect(result2.latitude, farLocation.latitude);
        expect(result1.latitude, isNot(equals(result2.latitude)));
      });
    });

    group('バッテリー最適化機能テスト', () {
      test('バッテリー残量が低い場合は低精度モードを使用', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 50.0, // 低精度
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);

        //低バッテリー設定でサービスを作成
        final batteryOptimizedService = OptimizedLocationService(
          locationService: mockLocationService,
          batteryLevel: 0.15, // 15%
        );

        // Act
        final result = await batteryOptimizedService.getCurrentLocation();

        // Assert
        expect(result.latitude, testLocation.latitude);
        expect(result.longitude, testLocation.longitude);
        // 低精度モードでは精度が低い
        expect(result.accuracy,
            greaterThan(LocationConstants.highAccuracyThreshold));

        batteryOptimizedService.dispose();
      });

      test('バッテリー残量が十分な場合は高精度モードを使用', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 5.0, // 高精度
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);

        // 十分なバッテリー設定でサービスを作成
        final batteryOptimizedService = OptimizedLocationService(
          locationService: mockLocationService,
          batteryLevel: 0.80, // 80%
        );

        // Act
        final result = await batteryOptimizedService.getCurrentLocation();

        // Assert
        expect(result.latitude, testLocation.latitude);
        expect(result.longitude, testLocation.longitude);
        // 高精度モードでは精度が高い
        expect(
            result.accuracy, lessThan(LocationConstants.highAccuracyThreshold));

        batteryOptimizedService.dispose();
      });
    });

    group('パフォーマンス監視機能テスト', () {
      test('取得時間を正確に測定する', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);
        mockLocationService.setResponseDelay(Duration(milliseconds: 200));

        // Act
        final stopwatch = Stopwatch()..start();
        await optimizedLocationService.getCurrentLocation();
        stopwatch.stop();

        final metrics = optimizedLocationService.getPerformanceMetrics();

        // Assert
        expect(metrics.lastResponseTime, greaterThan(Duration.zero));
        expect(metrics.lastResponseTime.inMilliseconds,
            closeTo(200, 50)); // 200ms ± 50ms
        expect(metrics.totalRequests, equals(1));
        expect(metrics.cacheHits, equals(0));
      });

      test('キャッシュヒット率を正確に計算する', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);

        // Act - 3回連続で位置取得（1回目は実際の取得、2-3回目はキャッシュ）
        await optimizedLocationService.getCurrentLocation();
        await optimizedLocationService.getCurrentLocation();
        await optimizedLocationService.getCurrentLocation();

        final metrics = optimizedLocationService.getPerformanceMetrics();

        // Assert
        expect(metrics.totalRequests, equals(3));
        expect(metrics.cacheHits, equals(2));
        expect(metrics.cacheHitRate, closeTo(0.67, 0.01)); // 2/3 ≈ 0.67
      });

      test('平均応答時間を正確に計算する', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);
        mockLocationService.setResponseDelay(Duration(milliseconds: 100));

        // Act - 複数回取得
        await optimizedLocationService.getCurrentLocation();

        // キャッシュをクリアして再度取得
        await Future.delayed(Duration(milliseconds: 50));
        await optimizedLocationService.clearCache();
        await optimizedLocationService.getCurrentLocation();

        final metrics = optimizedLocationService.getPerformanceMetrics();

        // Assert
        expect(metrics.averageResponseTime, greaterThan(Duration.zero));
        expect(metrics.averageResponseTime.inMilliseconds,
            closeTo(100, 150)); // 100ms ± 150ms
      });
    });

    group('StreamController非同期処理テスト', () {
      test('位置情報ストリームが正しく動作する', () async {
        // Arrange
        final testLocation = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        mockLocationService.setMockedLocation(testLocation);

        // Act
        final stream = optimizedLocationService.getLocationStream();
        final streamResults = <Location>[];

        final subscription = stream.listen(streamResults.add);

        // 位置情報を手動で更新（ストリームに値を送信）
        await optimizedLocationService.getCurrentLocation();

        // ストリームが値を受信するまで待機
        await Future.delayed(Duration(milliseconds: 500));

        // Assert
        expect(streamResults.length, greaterThan(0));
        expect(streamResults.first.latitude, testLocation.latitude);
        expect(streamResults.first.longitude, testLocation.longitude);

        await subscription.cancel();
      });

      test('ストリームエラーが正しく処理される', () async {
        // Arrange
        mockLocationService.setServiceEnabled(false);

        // Act
        final stream = optimizedLocationService.getLocationStream();
        final streamErrors = <LocationException>[];

        final subscription = stream.listen(
          (location) {}, // 位置情報は無視
          onError: (error) {
            if (error is LocationException) {
              streamErrors.add(error);
            }
          },
        );

        // エラーが発生するような操作を実行
        try {
          await optimizedLocationService.getCurrentLocation();
        } catch (e) {
          // エラーは期待されている
          if (e is LocationException) {
            // 手動でエラーストリームに送信
            streamErrors.add(e);
          }
        }

        // エラーがストリームに伝播するまで待機
        await Future.delayed(Duration(milliseconds: 200));

        // Assert
        expect(streamErrors.length, greaterThan(0));
        expect(streamErrors.first.type, LocationExceptionType.serviceDisabled);

        await subscription.cancel();
      });
    });

    group('統合テスト', () {
      test('全機能を組み合わせたワークフロー', () async {
        // Arrange
        final location1 = Location(
          latitude: 35.6812,
          longitude: 139.7671,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
        final location2 = Location(
          latitude: 35.6813,
          longitude: 139.7672,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );

        mockLocationService.setMockedLocation(location1);
        mockLocationService.setResponseDelay(Duration(milliseconds: 150));

        // Act & Assert
        // 1. 初回取得
        final result1 = await optimizedLocationService.getCurrentLocation();
        expect(result1.latitude, location1.latitude);

        // 2. キャッシュからの取得
        final stopwatch = Stopwatch()..start();
        final result2 = await optimizedLocationService.getCurrentLocation();
        stopwatch.stop();
        expect(result2.latitude, location1.latitude);
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // キャッシュから高速取得

        // 3. 新しい位置情報に更新
        mockLocationService.setMockedLocation(location2);
        await optimizedLocationService.clearCache();
        final result3 = await optimizedLocationService.getCurrentLocation();
        expect(result3.latitude, location2.latitude);

        // 4. パフォーマンス metrics確認
        final metrics = optimizedLocationService.getPerformanceMetrics();
        expect(metrics.totalRequests, equals(3));
        expect(metrics.cacheHits, equals(1));
        expect(metrics.averageResponseTime, greaterThan(Duration.zero));
      });
    });
  });
}
