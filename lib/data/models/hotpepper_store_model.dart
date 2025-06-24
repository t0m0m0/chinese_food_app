/// ホットペッパーAPIレスポンス用のStoreモデル
class HotpepperStoreModel {
  /// 店舗ID
  final String id;

  /// 店名
  final String name;

  /// 住所
  final String address;

  /// 緯度
  final double lat;

  /// 経度
  final double lng;

  /// 店舗URL
  final String? url;

  /// 電話番号
  final String? phone;

  /// 営業時間
  final String? openHours;

  /// 定休日
  final String? holiday;

  /// 店舗画像URL
  final String? photoUrl;

  /// ジャンル
  final String? genre;

  /// 予算
  final String? budget;

  /// アクセス情報
  final String? access;

  HotpepperStoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.url,
    this.phone,
    this.openHours,
    this.holiday,
    this.photoUrl,
    this.genre,
    this.budget,
    this.access,
  });

  /// ホットペッパーAPIのJSONからモデルを作成
  factory HotpepperStoreModel.fromJson(Map<String, dynamic> json) {
    return HotpepperStoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      url: json['urls']?['pc'] as String?,
      phone: json['tel'] as String?,
      openHours: json['open'] as String?,
      holiday: json['close'] as String?,
      photoUrl: json['photo']?['pc']?['l'] as String?,
      genre: json['genre']?['name'] as String?,
      budget: json['budget']?['name'] as String?,
      access: json['access'] as String?,
    );
  }

  /// Domain層のStoreエンティティに変換
  Map<String, dynamic> toStoreEntity() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': null, // ホットペッパーからの取得時はnull
      'memo': '', // 初期値は空文字
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HotpepperStoreModel) return false;

    return id == other.id &&
        name == other.name &&
        address == other.address &&
        lat == other.lat &&
        lng == other.lng;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return Object.hash(id, name, address, lat, lng);
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'HotpepperStoreModel{id: $id, name: $name, address: $address, lat: $lat, lng: $lng}';
  }
}

/// ホットペッパーAPI検索結果のレスポンスモデル
class HotpepperSearchResponse {
  /// 検索結果
  final List<HotpepperStoreModel> results;

  /// 検索結果の総件数
  final int totalCount;

  /// 検索開始位置
  final int start;

  /// 1ページあたりの表示件数
  final int count;

  HotpepperSearchResponse({
    required this.results,
    required this.totalCount,
    required this.start,
    required this.count,
  });

  /// ホットペッパーAPIのJSONからレスポンスモデルを作成
  factory HotpepperSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsData = json['results'] as Map<String, dynamic>;
    final shops = resultsData['shop'] as List<dynamic>? ?? [];
    
    return HotpepperSearchResponse(
      results: shops
          .cast<Map<String, dynamic>>()
          .map((shopJson) => HotpepperStoreModel.fromJson(shopJson))
          .toList(),
      totalCount: resultsData['results_available'] as int? ?? 0,
      start: resultsData['results_start'] as int? ?? 1,
      count: resultsData['results_returned'] as int? ?? 0,
    );
  }

  /// 空の検索結果
  factory HotpepperSearchResponse.empty() {
    return HotpepperSearchResponse(
      results: [],
      totalCount: 0,
      start: 1,
      count: 0,
    );
  }

  /// 検索結果が空かどうか
  bool get isEmpty => results.isEmpty;

  /// 検索結果があるかどうか
  bool get isNotEmpty => results.isNotEmpty;
}