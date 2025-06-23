import '../../domain/entities/photo.dart';

class PhotoModel extends Photo {
  const PhotoModel({
    required super.id,
    required super.storeId,
    super.visitId,
    required super.filePath,
    required super.createdAt,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      visitId: map['visit_id'] as String?,
      filePath: map['file_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory PhotoModel.fromEntity(Photo photo) {
    return PhotoModel(
      id: photo.id,
      storeId: photo.storeId,
      visitId: photo.visitId,
      filePath: photo.filePath,
      createdAt: photo.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'visit_id': visitId,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PhotoModel copyWith({
    String? id,
    String? storeId,
    String? visitId,
    String? filePath,
    DateTime? createdAt,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}