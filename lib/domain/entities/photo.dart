class Photo {
  final String id;
  final String storeId;
  final String? visitId;
  final String filePath;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.storeId,
    this.visitId,
    required this.filePath,
    required this.createdAt,
  });

  Photo copyWith({
    String? id,
    String? storeId,
    String? visitId,
    String? filePath,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
