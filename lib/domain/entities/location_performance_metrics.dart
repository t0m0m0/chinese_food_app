/// 位置情報サービスのパフォーマンス監視メトリクス
class LocationPerformanceMetrics {
  /// 最後のレスポンス時間
  final Duration lastResponseTime;

  /// 平均レスポンス時間
  final Duration averageResponseTime;

  /// 総リクエスト数
  final int totalRequests;

  /// キャッシュヒット数
  final int cacheHits;

  /// キャッシュヒット率 (0.0 - 1.0)
  final double cacheHitRate;

  /// 最後のエラー
  final String? lastError;

  /// エラー率 (0.0 - 1.0)
  final double errorRate;

  /// CPU使用率（推定値）
  final double cpuUsage;

  /// メモリ使用量（推定値、MB）
  final double memoryUsage;

  /// バッテリー最適化モードが有効かどうか
  final bool isBatteryOptimized;

  const LocationPerformanceMetrics({
    required this.lastResponseTime,
    required this.averageResponseTime,
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheHitRate,
    this.lastError,
    required this.errorRate,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.isBatteryOptimized,
  });

  /// 空のメトリクス（初期状態）
  factory LocationPerformanceMetrics.empty() {
    return const LocationPerformanceMetrics(
      lastResponseTime: Duration.zero,
      averageResponseTime: Duration.zero,
      totalRequests: 0,
      cacheHits: 0,
      cacheHitRate: 0.0,
      lastError: null,
      errorRate: 0.0,
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      isBatteryOptimized: false,
    );
  }

  /// パフォーマンス改善の提案を生成
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    if (averageResponseTime.inMilliseconds > 2000) {
      suggestions.add('位置情報の取得に時間がかかっています。キャッシュの使用を検討してください。');
    }

    if (cacheHitRate < 0.3 && totalRequests > 5) {
      suggestions.add('キャッシュヒット率が低いです。キャッシュ戦略の見直しを検討してください。');
    }

    if (errorRate > 0.1) {
      suggestions.add('エラー率が高いです。権限チェックとエラーハンドリングを確認してください。');
    }

    if (cpuUsage > 0.8) {
      suggestions.add('CPU使用率が高いです。処理の最適化を検討してください。');
    }

    if (memoryUsage > 50.0) {
      suggestions.add('メモリ使用量が多いです。不要なキャッシュのクリアを検討してください。');
    }

    if (!isBatteryOptimized && averageResponseTime.inMilliseconds > 1500) {
      suggestions.add('バッテリー最適化モードの使用を検討してください。');
    }

    return suggestions;
  }

  /// パフォーマンススコア (0-100)
  int get performanceScore {
    int score = 100;

    // レスポンス時間による減点
    if (averageResponseTime.inMilliseconds > 1500) {
      score -= 20;
    } else if (averageResponseTime.inMilliseconds > 1000) {
      score -= 10;
    }

    // キャッシュヒット率による加点/減点
    if (cacheHitRate > 0.7) {
      score += 10;
    } else if (cacheHitRate < 0.3) {
      score -= 15;
    }

    // エラー率による減点
    if (errorRate > 0.1) {
      score -= 25;
    } else if (errorRate > 0.05) {
      score -= 10;
    }

    // CPU/メモリ使用量による減点
    if (cpuUsage > 0.8) score -= 15;
    if (memoryUsage > 50.0) score -= 10;

    // バッテリー最適化による加点
    if (isBatteryOptimized) score += 5;

    return score.clamp(0, 100);
  }

  @override
  String toString() {
    return 'LocationPerformanceMetrics('
        'lastResponseTime: $lastResponseTime, '
        'averageResponseTime: $averageResponseTime, '
        'totalRequests: $totalRequests, '
        'cacheHits: $cacheHits, '
        'cacheHitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
        'errorRate: ${(errorRate * 100).toStringAsFixed(1)}%, '
        'performanceScore: $performanceScore'
        ')';
  }
}
