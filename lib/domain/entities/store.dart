enum StoreStatus {
  wantToGo('want_to_go'),
  visited('visited'),
  bad('bad');

  const StoreStatus(this.value);
  final String value;
}

class Store {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final StoreStatus? status;
  final String? memo;
  final DateTime createdAt;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.status,
    this.memo,
    required this.createdAt,
  });

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
