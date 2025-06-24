/// 店舗のステータス
enum StoreStatus {
  /// 行きたい
  wantToGo('want_to_go'),

  /// 行った
  visited('visited'),

  /// 興味なし
  bad('bad');

  const StoreStatus(this.value);
  final String value;

  /// 文字列からStoreStatusを作成
  static StoreStatus fromString(String value) {
    switch (value) {
      case 'want_to_go':
        return StoreStatus.wantToGo;
      case 'visited':
        return StoreStatus.visited;
      case 'bad':
        return StoreStatus.bad;
      default:
        throw ArgumentError('Invalid StoreStatus value: $value');
    }
  }
}

/// 店舗エンティティ
class Store {
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

  /// ステータス
  final StoreStatus? status;

  /// メモ
  final String? memo;

  /// 作成日時
  final DateTime createdAt;

  /// Store エンティティのコンストラクタ
  ///
  /// [id] - 店舗ID（必須、空文字不可）
  /// [name] - 店名（必須、空文字不可）
  /// [address] - 住所（必須、空文字不可）
  /// [lat] - 緯度（必須、-90.0~90.0の範囲）
  /// [lng] - 経度（必須、-180.0~180.0の範囲）
  /// [status] - ステータス（任意）
  /// [memo] - メモ（任意、デフォルト空文字）
  /// [createdAt] - 作成日時（必須）
  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.status,
    this.memo = '',
    required this.createdAt,
  }) {
    // バリデーション
    if (id.isEmpty) {
      throw ArgumentError('Store ID cannot be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError('Store name cannot be empty');
    }
    if (address.isEmpty) {
      throw ArgumentError('Store address cannot be empty');
    }
    if (lat < -90.0 || lat > 90.0) {
      throw ArgumentError('Latitude must be between -90.0 and 90.0, got: $lat');
    }
    if (lng < -180.0 || lng > 180.0) {
      throw ArgumentError('Longitude must be between -180.0 and 180.0, got: $lng');
    }
  }

  /// JSONからStore エンティティを作成
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      status: json['status'] != null
          ? StoreStatus.fromString(json['status'] as String)
          : null,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Store エンティティをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status?.value,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Store) return false;

    return id == other.id &&
        name == other.name &&
        address == other.address &&
        lat == other.lat &&
        lng == other.lng &&
        status == other.status &&
        memo == other.memo &&
        createdAt == other.createdAt;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      address,
      lat,
      lng,
      status,
      memo,
      createdAt,
    );
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'Store{id: $id, name: $name, address: $address, lat: $lat, lng: $lng, status: $status, memo: $memo, createdAt: $createdAt}';
  }

  /// Store エンティティをコピーして一部を変更
  Store copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    StoreStatus? status,
    String? memo,
    DateTime? createdAt,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
