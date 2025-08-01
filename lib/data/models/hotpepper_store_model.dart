import 'dart:convert';

/// HotPepper API から取得する店舗情報のデータモデル
///
/// HotPepper API のレスポンス形式に対応した店舗データを表現する
/// Data層でのみ使用され、Domain層のStoreエンティティとは分離される
class HotpepperStoreModel {
  /// 店舗ID（HotPepper API固有）
  final String id;

  /// 店舗名
  final String name;

  /// 住所
  final String address;

  /// 緯度 (WGS84)
  final double? lat;

  /// 経度 (WGS84)
  final double? lng;

  /// ジャンル名 (例: "中華料理")
  final String? genre;

  /// 予算 (例: "～1000円")
  final String? budget;

  /// アクセス情報 (例: "JR新宿駅徒歩5分")
  final String? access;

  /// PC用URL
  final String? urlPc;

  /// モバイル用URL
  final String? urlMobile;

  /// 店舗写真URL (Large サイズ)
  final String? photo;

  /// 営業時間開始
  final String? open;

  /// 営業時間終了
  final String? close;

  /// キャッチコピー・特徴
  final String? catch_;

  /// HotpepperStoreModel コンストラクタ
  ///
  /// [id] 店舗ID（必須）
  /// [name] 店舗名（必須）
  /// [address] 住所（必須）
  /// その他のフィールドはオプショナル
  const HotpepperStoreModel({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.genre,
    this.budget,
    this.access,
    this.urlPc,
    this.urlMobile,
    this.photo,
    this.open,
    this.close,
    this.catch_,
  });

  /// HotPepper API のJSONレスポンスからモデルを作成
  ///
  /// [json] HotPepper API のshopオブジェクト
  /// 戻り値: [HotpepperStoreModel] インスタンス
  factory HotpepperStoreModel.fromJson(Map<String, dynamic> json) {
    return HotpepperStoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      genre: json['genre']?['name'] as String?,
      budget: json['budget']?['name'] as String?,
      access: json['access'] as String?,
      urlPc: json['urls']?['pc'] as String?,
      urlMobile: json['urls']?['mobile'] as String?,
      photo: json['photo']?['mobile']?['l'] as String?,
      open: json['open'] as String?,
      close: json['close'] as String?,
      catch_: json['catch'] as String?,
    );
  }

  /// モデルをJSONに変換
  ///
  /// 戻り値: JSON形式のMap
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'genre': genre,
      'budget': budget,
      'access': access,
      'urlPc': urlPc,
      'urlMobile': urlMobile,
      'photo': photo,
      'open': open,
      'close': close,
      'catch': catch_,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotpepperStoreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HotpepperStoreModel(id: $id, name: $name, address: $address)';
  }
}

/// HotPepper API 検索結果のレスポンスモデル
///
/// 店舗検索APIの結果データとページング情報を格納する
class HotpepperSearchResponse {
  /// 検索結果の店舗リスト
  final List<HotpepperStoreModel> shops;

  /// 検索条件に該当する総件数
  final int resultsAvailable;

  /// 今回のレスポンスで返された件数
  final int resultsReturned;

  /// 検索開始位置（ページング用）
  final int resultsStart;

  /// HotpepperSearchResponse コンストラクタ
  ///
  /// [shops] 店舗リスト
  /// [resultsAvailable] 総件数
  /// [resultsReturned] 返却件数
  /// [resultsStart] 開始位置
  const HotpepperSearchResponse({
    required this.shops,
    required this.resultsAvailable,
    required this.resultsReturned,
    required this.resultsStart,
  });

  /// HotPepper API のJSONレスポンスからモデルを作成
  ///
  /// [json] HotPepper API の全体レスポンス
  /// 戻り値: [HotpepperSearchResponse] インスタンス
  factory HotpepperSearchResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    final shopList = results['shop'] as List<dynamic>? ?? [];

    return HotpepperSearchResponse(
      shops: shopList
          .map((shop) =>
              HotpepperStoreModel.fromJson(shop as Map<String, dynamic>))
          .toList(),
      resultsAvailable: results['results_available'] as int? ?? 0,
      resultsReturned: _parseIntSafely(results['results_returned']) ?? 0,
      resultsStart: results['results_start'] as int? ?? 1,
    );
  }

  /// 文字列または数値を安全にintに変換
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// JSON文字列からレスポンスモデルを作成
  ///
  /// [jsonString] HotPepper API からのJSON文字列
  /// 戻り値: [HotpepperSearchResponse] インスタンス
  static HotpepperSearchResponse fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return HotpepperSearchResponse.fromJson(json);
  }

  /// 検索結果があるかどうか
  bool get hasResults => shops.isNotEmpty;

  /// 次のページがあるかどうか
  bool get hasMoreResults =>
      resultsAvailable > resultsStart + resultsReturned - 1;

  @override
  String toString() {
    return 'HotpepperSearchResponse(shops: ${shops.length}, available: $resultsAvailable)';
  }
}
