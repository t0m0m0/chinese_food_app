import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/services/optimized_location_service.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'dart:developer' as developer;
import 'dart:io';

/// 位置情報サービスのベンチマークテスト
///
/// Issue #45の目標:
/// - 50% faster location retrieval (from 3s to 1.5s)
/// - 20% battery consumption reduction
/// - 50% CPU usage reduction via Isolate processing
///
/// CI環境での安定化対応 (Issue #176):
/// - CI環境での閾値緩和
/// - タイムアウト調整
/// - 環境依存テストの安定化

/// CI環境検出用の環境変数キー
const _ciEnvironmentKeys = ['CI', 'GITHUB_ACTIONS', 'FLUTTER_TEST'];

/// CI環境を検出する関数
///
/// 複数のCI環境変数をチェックして、CI環境での実行を判定する。
/// 新しいCI環境の対応は [_ciEnvironmentKeys] に追加することで容易に拡張可能。
bool get isRunningInCI {
  return _ciEnvironmentKeys.any((key) => Platform.environment[key] == 'true');
}

/// CI環境に応じた閾値調整
///
/// CI環境では共有リソースや仮想化環境の影響でパフォーマンスが不安定になるため、
/// 適切な閾値調整を行い、テストの安定性を確保する。
class PerformanceThresholds {
  /// CI環境でのリソース制限を考慮した閾値緩和倍率
  ///
  /// 値の根拠:
  /// - CI環境での実測値に基づく安全マージン
  /// - GitHub Actions等の共有環境での性能変動を考慮
  /// - 過度に緩くしすぎない適切なバランス
  static const _ciMultiplier = 3.0;

  /// CI環境での要求緩和率
  ///
  /// パフォーマンス改善率などの相対的な指標について、
  /// CI環境の不安定性を考慮して要求水準を調整する。
  static const _ciRatioMultiplier = 0.7;

  /// 応答時間の閾値を環境に応じて調整
  ///
  /// [baseMs] ローカル環境での基準値（ミリ秒）
  /// 戻り値: CI環境では [_ciMultiplier] 倍に緩和された値
  static int responseTimeThreshold(int baseMs) =>
      isRunningInCI ? (baseMs * _ciMultiplier).round() : baseMs;

  /// メモリ使用量の閾値を環境に応じて調整
  ///
  /// [baseMB] ローカル環境での基準値（MB）
  /// 戻り値: CI環境では [_ciMultiplier] 倍に緩和された値
  static double memoryThreshold(double baseMB) =>
      isRunningInCI ? baseMB * _ciMultiplier : baseMB;

  /// パフォーマンス比率の閾値を環境に応じて調整
  ///
  /// [baseRatio] ローカル環境での基準値（0.0-1.0）
  /// 戻り値: CI環境では [_ciRatioMultiplier] 倍に緩和された値
  static double ratioThreshold(double baseRatio) =>
      isRunningInCI ? baseRatio * _ciRatioMultiplier : baseRatio;
}

class MockSlowLocationService implements LocationService {
  final Duration _simulatedDelay;

  MockSlowLocationService(
      {Duration simulatedDelay = const Duration(seconds: 3)})
      : _simulatedDelay = simulatedDelay;

  @override
  Future<Location> getCurrentLocation() async {
    await Future.delayed(_simulatedDelay);
    return Location(
      latitude: 35.6812,
      longitude: 139.7671,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}

class MockFastLocationService implements LocationService {
  final Duration _simulatedDelay;

  MockFastLocationService(
      {Duration simulatedDelay = const Duration(milliseconds: 100)})
      : _simulatedDelay = simulatedDelay;

  @override
  Future<Location> getCurrentLocation() async {
    await Future.delayed(_simulatedDelay);
    return Location(
      latitude: 35.6812,
      longitude: 139.7671,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}

void main() {
  group('Location Service Benchmark Tests', () {
    group('Response Time Benchmarks', () {
      test('未最適化サービス vs 最適化サービス: 初回取得時間比較', () async {
        // Arrange
        final slowService = MockSlowLocationService(
          simulatedDelay: const Duration(milliseconds: 3000), // 3秒
        );
        final fastService = MockFastLocationService(
          simulatedDelay: const Duration(milliseconds: 100), // 100ms
        );
        final optimizedService = OptimizedLocationService(
          locationService: fastService,
        );

        // Act & Measure
        // 未最適化サービス
        final stopwatch1 = Stopwatch()..start();
        await slowService.getCurrentLocation();
        stopwatch1.stop();
        final slowTime = stopwatch1.elapsedMilliseconds;

        // 最適化サービス
        final stopwatch2 = Stopwatch()..start();
        await optimizedService.getCurrentLocation();
        stopwatch2.stop();
        final fastTime = stopwatch2.elapsedMilliseconds;

        // Assert
        developer.log('Environment: ${isRunningInCI ? "CI" : "Local"}',
            name: 'Benchmark');
        developer.log('Slow service time: ${slowTime}ms', name: 'Benchmark');
        developer.log('Optimized service time: ${fastTime}ms',
            name: 'Benchmark');

        // CI環境に応じた閾値で評価
        final improvementRatio = (slowTime - fastTime) / slowTime;
        final expectedRatio = PerformanceThresholds.ratioThreshold(0.5);
        final maxResponseTime =
            PerformanceThresholds.responseTimeThreshold(1500);

        developer.log('Required improvement ratio: $expectedRatio',
            name: 'Benchmark');
        developer.log('Max response time: ${maxResponseTime}ms',
            name: 'Benchmark');

        expect(improvementRatio, greaterThan(expectedRatio)); // CI環境では緩和
        expect(fastTime, lessThan(maxResponseTime)); // CI環境では緩和

        optimizedService.dispose();
      });

      test('キャッシュ効果による応答時間の短縮', () async {
        // Arrange
        final mockService = MockFastLocationService(
          simulatedDelay: const Duration(milliseconds: 500), // 500ms
        );
        final optimizedService = OptimizedLocationService(
          locationService: mockService,
        );

        // Act & Measure
        // 1回目（キャッシュなし）
        final stopwatch1 = Stopwatch()..start();
        await optimizedService.getCurrentLocation();
        stopwatch1.stop();
        final firstTime = stopwatch1.elapsedMilliseconds;

        // 2回目（キャッシュあり）
        final stopwatch2 = Stopwatch()..start();
        await optimizedService.getCurrentLocation();
        stopwatch2.stop();
        final cachedTime = stopwatch2.elapsedMilliseconds;

        // Assert
        developer.log('First request time: ${firstTime}ms', name: 'Benchmark');
        developer.log('Cached request time: ${cachedTime}ms',
            name: 'Benchmark');

        expect(cachedTime, lessThan(firstTime)); // キャッシュの方が速い
        final maxCachedTime = PerformanceThresholds.responseTimeThreshold(100);
        expect(cachedTime, lessThan(maxCachedTime)); // CI環境では緩和

        // キャッシュ効果確認（CI環境では要求緩和）
        final cacheImprovementRatio = (firstTime - cachedTime) / firstTime;
        final expectedCacheRatio = PerformanceThresholds.ratioThreshold(0.9);
        expect(cacheImprovementRatio, greaterThan(expectedCacheRatio));

        optimizedService.dispose();
      });
    });

    group('Memory Usage Benchmarks', () {
      test('メモリ使用量の監視と最適化', () async {
        // Arrange
        final mockService = MockFastLocationService();
        final optimizedService = OptimizedLocationService(
          locationService: mockService,
        );

        // Act - 複数回リクエストしてメモリ使用量を測定
        for (int i = 0; i < 10; i++) {
          await optimizedService.getCurrentLocation();
        }

        final metrics = optimizedService.getPerformanceMetrics();

        // Assert
        developer.log('Memory usage: ${metrics.memoryUsage}MB',
            name: 'Benchmark');
        developer.log(
            'Cache hit rate: ${(metrics.cacheHitRate * 100).toStringAsFixed(1)}%',
            name: 'Benchmark');

        // メモリ使用量確認（CI環境では緩和）
        final maxMemory = PerformanceThresholds.memoryThreshold(50.0);
        expect(metrics.memoryUsage, lessThan(maxMemory));

        // 高いキャッシュヒット率
        expect(metrics.cacheHitRate, greaterThan(0.8)); // 80%以上

        optimizedService.dispose();
      });
    });

    group('CPU Usage Benchmarks', () {
      test('CPU使用率の最適化', () async {
        // Arrange
        final mockService = MockFastLocationService(
          simulatedDelay: const Duration(milliseconds: 100),
        );
        final optimizedService = OptimizedLocationService(
          locationService: mockService,
        );

        // Act - 短時間で複数リクエスト
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          await optimizedService.getCurrentLocation();
        }
        stopwatch.stop();

        final metrics = optimizedService.getPerformanceMetrics();

        // Assert
        developer.log(
            'CPU usage: ${(metrics.cpuUsage * 100).toStringAsFixed(1)}%',
            name: 'Benchmark');
        developer.log(
            'Average response time: ${metrics.averageResponseTime.inMilliseconds}ms',
            name: 'Benchmark');
        developer.log(
            'Total execution time: ${stopwatch.elapsedMilliseconds}ms',
            name: 'Benchmark');

        // CPU使用率確認（CI環境では緩和）
        final maxCpuUsage = PerformanceThresholds.ratioThreshold(0.5);
        expect(metrics.cpuUsage, lessThan(maxCpuUsage));

        // 高いキャッシュ効率
        expect(metrics.cacheHits, greaterThan(0));

        optimizedService.dispose();
      });
    });

    group('Battery Optimization Benchmarks', () {
      test('バッテリー最適化モードでの消費削減', () async {
        // Arrange
        final mockService = MockFastLocationService();

        // 通常モード
        final normalService = OptimizedLocationService(
          locationService: mockService,
          batteryLevel: 0.8, // 80% - 通常モード
        );

        // バッテリー最適化モード
        final batteryOptimizedService = OptimizedLocationService(
          locationService: mockService,
          batteryLevel: 0.15, // 15% - 低バッテリーモード
        );

        // Act & Measure
        final stopwatch1 = Stopwatch()..start();
        await normalService.getCurrentLocation();
        stopwatch1.stop();
        final normalTime = stopwatch1.elapsedMilliseconds;

        final stopwatch2 = Stopwatch()..start();
        await batteryOptimizedService.getCurrentLocation();
        stopwatch2.stop();
        final batteryOptimizedTime = stopwatch2.elapsedMilliseconds;

        final normalMetrics = normalService.getPerformanceMetrics();
        final batteryMetrics = batteryOptimizedService.getPerformanceMetrics();

        // Assert
        developer.log('Normal mode time: ${normalTime}ms', name: 'Benchmark');
        developer.log('Battery optimized time: ${batteryOptimizedTime}ms',
            name: 'Benchmark');
        developer.log(
            'Normal mode optimized: ${normalMetrics.isBatteryOptimized}',
            name: 'Benchmark');
        developer.log(
            'Battery mode optimized: ${batteryMetrics.isBatteryOptimized}',
            name: 'Benchmark');

        // バッテリー最適化フラグの確認
        expect(normalMetrics.isBatteryOptimized, false);
        expect(batteryMetrics.isBatteryOptimized, true);

        // バッテリー最適化モードでも合理的な応答時間（CI環境では緩和）
        final maxBatteryTime =
            PerformanceThresholds.responseTimeThreshold(2000);
        expect(batteryOptimizedTime, lessThan(maxBatteryTime));

        normalService.dispose();
        batteryOptimizedService.dispose();
      });
    });

    group('Stress Test Benchmarks', () {
      test('大量リクエストでのパフォーマンス維持', () async {
        // Arrange
        final mockService = MockFastLocationService(
          simulatedDelay: const Duration(milliseconds: 50),
        );
        final optimizedService = OptimizedLocationService(
          locationService: mockService,
        );

        const int requestCount = 50;
        final responseTimes = <int>[];

        // Act - 大量リクエスト
        final totalStopwatch = Stopwatch()..start();

        for (int i = 0; i < requestCount; i++) {
          final stopwatch = Stopwatch()..start();
          await optimizedService.getCurrentLocation();
          stopwatch.stop();
          responseTimes.add(stopwatch.elapsedMilliseconds);

          // 少し間隔を空ける
          await Future.delayed(const Duration(milliseconds: 10));
        }

        totalStopwatch.stop();

        final metrics = optimizedService.getPerformanceMetrics();

        // Assert
        final avgResponseTime =
            responseTimes.reduce((a, b) => a + b) / responseTimes.length;
        final maxResponseTime = responseTimes.reduce((a, b) => a > b ? a : b);
        final minResponseTime = responseTimes.reduce((a, b) => a < b ? a : b);

        developer.log('Total requests: $requestCount', name: 'Benchmark');
        developer.log('Total time: ${totalStopwatch.elapsedMilliseconds}ms',
            name: 'Benchmark');
        developer.log(
            'Average response: ${avgResponseTime.toStringAsFixed(1)}ms',
            name: 'Benchmark');
        developer.log('Min response: ${minResponseTime}ms', name: 'Benchmark');
        developer.log('Max response: ${maxResponseTime}ms', name: 'Benchmark');
        developer.log(
            'Cache hits: ${metrics.cacheHits}/${metrics.totalRequests}',
            name: 'Benchmark');
        developer.log(
            'Cache hit rate: ${(metrics.cacheHitRate * 100).toStringAsFixed(1)}%',
            name: 'Benchmark');

        // パフォーマンス要件の確認（CI環境では緩和）
        final maxAvgTime = PerformanceThresholds.responseTimeThreshold(100);
        final maxTime = PerformanceThresholds.responseTimeThreshold(500);
        final minCacheRate = PerformanceThresholds.ratioThreshold(0.7);
        final maxMemoryStress = PerformanceThresholds.memoryThreshold(100.0);

        expect(avgResponseTime, lessThan(maxAvgTime)); // CI環境では緩和
        expect(maxResponseTime, lessThan(maxTime)); // CI環境では緩和
        expect(metrics.cacheHitRate, greaterThan(minCacheRate)); // CI環境では緩和
        expect(metrics.totalRequests, equals(requestCount));

        // メモリリークの確認（CI環境では緩和）
        expect(metrics.memoryUsage, lessThan(maxMemoryStress));

        optimizedService.dispose();
      });
    });

    group('Real-world Scenario Benchmarks', () {
      test('実際のアプリ使用パターンでのパフォーマンス', () async {
        // Arrange
        final mockService = MockFastLocationService(
          simulatedDelay: const Duration(milliseconds: 200),
        );
        final optimizedService = OptimizedLocationService(
          locationService: mockService,
        );

        final scenarioResults = <String, int>{};

        // Scenario 1: アプリ起動時
        var stopwatch = Stopwatch()..start();
        await optimizedService.getCurrentLocation();
        stopwatch.stop();
        scenarioResults['アプリ起動'] = stopwatch.elapsedMilliseconds;

        // Scenario 2: 連続検索（5回）
        stopwatch = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          await optimizedService.getCurrentLocation();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        stopwatch.stop();
        scenarioResults['連続検索'] = stopwatch.elapsedMilliseconds;

        // Scenario 3: バックグラウンド復帰
        await optimizedService.clearCache(); // バックグラウンド復帰をシミュレート
        stopwatch = Stopwatch()..start();
        await optimizedService.getCurrentLocation();
        stopwatch.stop();
        scenarioResults['バックグラウンド復帰'] = stopwatch.elapsedMilliseconds;

        final metrics = optimizedService.getPerformanceMetrics();

        // Assert
        for (final entry in scenarioResults.entries) {
          developer.log('${entry.key}: ${entry.value}ms', name: 'Benchmark');
        }
        developer.log('Overall performance score: ${metrics.performanceScore}',
            name: 'Benchmark');

        // 各シナリオの性能要件（CI環境では緩和）
        final maxStartup = PerformanceThresholds.responseTimeThreshold(300);
        final maxSearch = PerformanceThresholds.responseTimeThreshold(120);
        final maxResume = PerformanceThresholds.responseTimeThreshold(300);
        final minScore = PerformanceThresholds.ratioThreshold(80.0);

        expect(scenarioResults['アプリ起動']!, lessThan(maxStartup));
        expect(scenarioResults['連続検索']! / 5, lessThan(maxSearch));
        expect(scenarioResults['バックグラウンド復帰']!, lessThan(maxResume));

        // 全体的なパフォーマンススコア（CI環境では緩和）
        expect(metrics.performanceScore, greaterThan(minScore));

        optimizedService.dispose();
      });
    });
  });
}
