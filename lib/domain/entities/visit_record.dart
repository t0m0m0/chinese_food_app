class VisitRecord {
  final String id;
  final String storeId;
  final DateTime visitedAt;
  final String menu;
  final String memo;
  final DateTime createdAt;

  const VisitRecord({
    required this.id,
    required this.storeId,
    required this.visitedAt,
    required this.menu,
    required this.memo,
    required this.createdAt,
  });

  VisitRecord copyWith({
    String? id,
    String? storeId,
    DateTime? visitedAt,
    String? menu,
    String? memo,
    DateTime? createdAt,
  }) {
    return VisitRecord(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      visitedAt: visitedAt ?? this.visitedAt,
      menu: menu ?? this.menu,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
