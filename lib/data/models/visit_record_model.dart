import '../../domain/entities/visit_record.dart';

class VisitRecordModel extends VisitRecord {
  const VisitRecordModel({
    required super.id,
    required super.storeId,
    required super.visitedAt,
    required super.menu,
    required super.memo,
    required super.createdAt,
  });

  factory VisitRecordModel.fromMap(Map<String, dynamic> map) {
    return VisitRecordModel(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      visitedAt: DateTime.parse(map['visited_at'] as String),
      menu: map['menu'] as String,
      memo: map['memo'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory VisitRecordModel.fromEntity(VisitRecord visitRecord) {
    return VisitRecordModel(
      id: visitRecord.id,
      storeId: visitRecord.storeId,
      visitedAt: visitRecord.visitedAt,
      menu: visitRecord.menu,
      memo: visitRecord.memo,
      createdAt: visitRecord.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'visited_at': visitedAt.toIso8601String(),
      'menu': menu,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VisitRecordModel copyWith({
    String? id,
    String? storeId,
    DateTime? visitedAt,
    String? menu,
    String? memo,
    DateTime? createdAt,
  }) {
    return VisitRecordModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitedAt: visitedAt ?? this.visitedAt,
      menu: menu ?? this.menu,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}