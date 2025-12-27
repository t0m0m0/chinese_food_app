import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/search_config.dart';
import '../../core/exceptions/unified_exceptions_export.dart';
import '../../core/types/result.dart';
import '../../core/utils/grid_search_generator.dart';
import '../entities/store.dart';
import '../repositories/store_repository.dart';

/// 広域検索ユースケース
///
/// HotPepper APIのrange制限（最大3km）を超える検索範囲に対応するため、
/// 複数の検索ポイントで並列検索を行い、結果をマージする。
///
/// ## 使用例
/// ```dart
/// final usecase = WideAreaSearchUsecase(repository: storeRepository);
/// final result = await usecase.execute(
///   center: LatLng(35.6812, 139.7671),
///   radiusMeters: 10000, // 10km
///   keyword: '中華',
/// );
/// ```
class WideAreaSearchUsecase {
  final StoreRepository repository;

  WideAreaSearchUsecase({required this.repository});

  /// 広域検索を実行
  ///
  /// [center] 検索の中心座標
  /// [radiusMeters] 検索半径（メートル）
  /// [keyword] 検索キーワード
  /// [count] 各ポイントで取得する最大件数
  ///
  /// 返り値: 検索結果の店舗リスト（重複除去済み）
  Future<Result<List<Store>>> execute({
    required LatLng center,
    required double radiusMeters,
    String keyword = '中華',
    int count = 100,
  }) async {
    try {
      // 3km以下の場合は通常の単一検索
      if (!isWideAreaSearch(radiusMeters)) {
        final range = GridSearchGenerator.metersToApiRange(radiusMeters);
        final stores = await repository.searchStoresFromApi(
          lat: center.latitude,
          lng: center.longitude,
          keyword: keyword,
          range: range,
          count: count,
          start: 1,
        );
        return Success(stores);
      }

      // 広域検索: グリッドポイントを生成して並列検索
      final searchPoints = GridSearchGenerator.generateSearchPoints(
        center: center,
        radiusMeters: radiusMeters,
      );

      // 各ポイントで検索を実行（並列）
      final futures = searchPoints.map((point) async {
        try {
          return await repository.searchStoresFromApi(
            lat: point.latitude,
            lng: point.longitude,
            keyword: keyword,
            range: 5, // 最大範囲（3km）で検索
            count: count,
            start: 1,
          );
        } catch (_) {
          // 個別の検索エラーは無視して空リストを返す
          return <Store>[];
        }
      });

      final results = await Future.wait(futures);

      // 結果をマージして重複を除去
      final allStores = <Store>[];
      final seenIds = <String>{};

      for (final stores in results) {
        for (final store in stores) {
          if (!seenIds.contains(store.id)) {
            seenIds.add(store.id);
            allStores.add(store);
          }
        }
      }

      // 中心からの距離でソート
      allStores.sort((a, b) {
        final distA = GridSearchGenerator.calculateDistance(
          center,
          LatLng(a.lat, a.lng),
        );
        final distB = GridSearchGenerator.calculateDistance(
          center,
          LatLng(b.lat, b.lng),
        );
        return distA.compareTo(distB);
      });

      return Success(allStores);
    } catch (e) {
      if (e is BaseException) {
        return Failure(e);
      }
      return Failure(UnifiedNetworkException.api(e.toString()));
    }
  }

  /// 広域検索かどうかを判定
  bool isWideAreaSearch(double radiusMeters) {
    return radiusMeters > SearchConfig.maxApiRadiusMeters;
  }

  /// 検索に必要なAPI呼び出し回数を推定
  int estimateSearchCount({
    required LatLng center,
    required double radiusMeters,
  }) {
    return GridSearchGenerator.estimateApiCalls(
      center: center,
      radiusMeters: radiusMeters,
    );
  }
}
