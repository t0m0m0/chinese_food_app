import '../entities/store.dart';
import '../repositories/store_repository.dart';

/// 店舗検索機能を提供するUsecase
///
/// HotPepper APIを使用して中華料理店を検索し、結果を返す
class SearchStoresUsecase {
  final StoreRepository repository;

  SearchStoresUsecase(this.repository);

  /// 指定されたパラメータで店舗検索を実行する
  ///
  /// [params] 検索条件を含むパラメータ
  /// 戻り値として[SearchStoresResult]を返す
  Future<SearchStoresResult> execute(SearchStoresParams params) async {
    // パラメータ検証
    if (!params.hasValidSearchCriteria) {
      return SearchStoresResult.failure('検索条件が不正です。位置情報または住所を指定してください。');
    }

    try {
      final stores = await repository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      );

      return SearchStoresResult.success(stores);
    } on Exception catch (e) {
      return SearchStoresResult.failure('店舗検索中にエラーが発生しました: ${e.toString()}');
    } catch (e) {
      return SearchStoresResult.failure('予期しないエラーが発生しました: ${e.toString()}');
    }
  }
}

/// 店舗検索のパラメータクラス
///
/// 位置情報または住所のいずれかが必須
class SearchStoresParams {
  /// 緯度 (-90.0 〜 90.0)
  final double? lat;

  /// 経度 (-180.0 〜 180.0)
  final double? lng;

  /// 住所（都道府県、市区町村等）
  final String? address;

  /// キーワード（デフォルト：中華料理で検索）
  final String? keyword;

  /// 検索範囲 (1:300m, 2:500m, 3:1000m, 4:2000m, 5:3000m)
  final int range;

  /// 取得件数 (1-100)
  final int count;

  /// 検索開始位置 (1以上)
  final int start;

  const SearchStoresParams({
    this.lat,
    this.lng,
    this.address,
    this.keyword,
    this.range = 3,
    this.count = 20,
    this.start = 1,
  })  : assert(lat == null || (lat >= -90.0 && lat <= 90.0),
            '緯度は-90.0から90.0の範囲で指定してください'),
        assert(lng == null || (lng >= -180.0 && lng <= 180.0),
            '経度は-180.0から180.0の範囲で指定してください'),
        assert(range >= 1 && range <= 5, '検索範囲は1から5の間で指定してください'),
        assert(count >= 1 && count <= 100, '取得件数は1から100の間で指定してください'),
        assert(start >= 1, '検索開始位置は1以上で指定してください');

  /// 位置情報による検索が可能かどうか
  bool get hasLocationSearch => lat != null && lng != null;

  /// 住所による検索が可能かどうか
  bool get hasAddressSearch => address != null && address!.isNotEmpty;

  /// 有効な検索条件が設定されているかどうか
  bool get hasValidSearchCriteria => hasLocationSearch || hasAddressSearch;

  @override
  String toString() {
    return 'SearchStoresParams(lat: $lat, lng: $lng, address: $address, keyword: $keyword)';
  }
}

/// 店舗検索の実行結果クラス
///
/// 成功時は店舗リストを、失敗時はエラーメッセージを格納する
class SearchStoresResult {
  /// 検索で見つかった店舗のリスト（成功時のみ）
  final List<Store>? stores;

  /// エラーメッセージ（失敗時のみ）
  final String? error;

  /// 成功したかどうか
  final bool isSuccess;

  const SearchStoresResult._({
    this.stores,
    this.error,
    required this.isSuccess,
  });

  /// 成功結果を作成
  factory SearchStoresResult.success(List<Store> stores) {
    return SearchStoresResult._(
      stores: stores,
      isSuccess: true,
    );
  }

  /// 失敗結果を作成
  factory SearchStoresResult.failure(String error) {
    return SearchStoresResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// 店舗が見つかったかどうか
  bool get hasStores => stores != null && stores!.isNotEmpty;

  @override
  String toString() {
    if (isSuccess) {
      return 'SearchStoresResult.success(${stores?.length} stores)';
    } else {
      return 'SearchStoresResult.failure($error)';
    }
  }
}
