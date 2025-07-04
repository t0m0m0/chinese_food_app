import '../../domain/entities/store.dart';

class StoreModel extends Store {
  StoreModel({
    required super.id,
    required super.name,
    required super.address,
    required super.lat,
    required super.lng,
    super.imageUrl,
    super.status,
    super.memo,
    required super.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      status: map['status'] != null
          ? StoreStatus.values.firstWhere(
              (e) => e.value == map['status'],
              orElse: () => StoreStatus.wantToGo,
            )
          : null,
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory StoreModel.fromEntity(Store store) {
    return StoreModel(
      id: store.id,
      name: store.name,
      address: store.address,
      lat: store.lat,
      lng: store.lng,
      imageUrl: store.imageUrl,
      status: store.status,
      memo: store.memo,
      createdAt: store.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'status': status?.value,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  StoreModel copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? imageUrl,
    StoreStatus? status,
    bool resetStatus = false,
    String? memo,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      status: resetStatus ? null : (status ?? this.status),
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
