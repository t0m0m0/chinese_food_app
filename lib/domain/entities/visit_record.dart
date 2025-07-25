/// 訪問記録エンティティ
class VisitRecord {
  /// 訪問記録ID
  final String id;

  /// 店舗ID
  final String storeId;

  /// 訪問日時
  final DateTime visitedAt;

  /// 食べたメニュー
  final String menu;

  /// メモ・感想
  final String? memo;

  /// 記録作成日時
  final DateTime createdAt;

  /// VisitRecord エンティティのコンストラクタ
  ///
  /// [id] - 訪問記録ID（必須、空文字不可）
  /// [storeId] - 店舗ID（必須、空文字不可）
  /// [visitedAt] - 訪問日時（必須、未来日時不可）
  /// [menu] - 食べたメニュー（必須、空文字不可）
  /// [memo] - メモ・感想（任意、デフォルト空文字）
  /// [createdAt] - 記録作成日時（必須）
  VisitRecord({
    required this.id,
    required this.storeId,
    required this.visitedAt,
    required this.menu,
    this.memo = '',
    required this.createdAt,
  }) {
    // バリデーション
    if (id.isEmpty) {
      throw ArgumentError('VisitRecord ID cannot be empty');
    }
    if (storeId.isEmpty) {
      throw ArgumentError('Store ID cannot be empty');
    }
    if (menu.isEmpty) {
      throw ArgumentError('Menu cannot be empty');
    }
    if (menu.length > 100) {
      throw ArgumentError(
          'Menu must be 100 characters or less: ${menu.length} characters');
    }
    if (memo != null && memo!.length > 500) {
      throw ArgumentError(
          'Memo must be 500 characters or less: ${memo!.length} characters');
    }

    // 訪問日時が未来でないことを確認
    final now = DateTime.now();
    if (visitedAt.isAfter(now)) {
      throw ArgumentError('Visited date cannot be in the future: $visitedAt');
    }
  }

  /// JSONからVisitRecord エンティティを作成
  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    return VisitRecord(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      visitedAt: DateTime.parse(json['visited_at'] as String),
      menu: json['menu'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// VisitRecord エンティティをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'visited_at': visitedAt.toIso8601String(),
      'menu': menu,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VisitRecord) return false;

    return id == other.id &&
        storeId == other.storeId &&
        visitedAt == other.visitedAt &&
        menu == other.menu &&
        memo == other.memo &&
        createdAt == other.createdAt;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return Object.hash(
      id,
      storeId,
      visitedAt,
      menu,
      memo,
      createdAt,
    );
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'VisitRecord{id: $id, storeId: $storeId, visitedAt: $visitedAt, menu: $menu, memo: $memo, createdAt: $createdAt}';
  }

  /// VisitRecord エンティティをコピーして一部を変更
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
