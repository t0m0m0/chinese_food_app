/// 写真エンティティ
class Photo {
  /// 写真ID
  final String id;

  /// 店舗ID
  final String storeId;

  /// 訪問記録ID（任意）
  final String? visitId;

  /// ファイルパス
  final String filePath;

  /// 作成日時
  final DateTime createdAt;

  /// Photo エンティティのコンストラクタ
  ///
  /// [id] - 写真ID（必須、空文字不可）
  /// [storeId] - 店舗ID（必須、空文字不可）
  /// [visitId] - 訪問記録ID（任意）
  /// [filePath] - ファイルパス（必須、有効なパス形式）
  /// [createdAt] - 作成日時（必須）
  Photo({
    required this.id,
    required this.storeId,
    this.visitId,
    required this.filePath,
    required this.createdAt,
  }) {
    // バリデーション
    if (id.isEmpty) {
      throw ArgumentError('Photo ID cannot be empty');
    }
    if (storeId.isEmpty) {
      throw ArgumentError('Store ID cannot be empty');
    }
    if (filePath.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }
    
    // ファイルパスの基本的なバリデーション
    if (!filePath.startsWith('/') && !filePath.contains(':')) {
      throw ArgumentError('File path must be an absolute path: $filePath');
    }
  }

  /// JSONからPhoto エンティティを作成
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      visitId: json['visit_id'] as String?,
      filePath: json['file_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Photo エンティティをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'visit_id': visitId,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// ファイル拡張子を取得
  String get fileExtension {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }

  /// ファイル名を取得
  String get fileName {
    final lastSlashIndex = filePath.lastIndexOf('/');
    final lastBackslashIndex = filePath.lastIndexOf('\\');
    final separatorIndex = [lastSlashIndex, lastBackslashIndex].reduce(
      (a, b) => a > b ? a : b,
    );

    if (separatorIndex == -1) {
      return filePath;
    }
    return filePath.substring(separatorIndex + 1);
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Photo) return false;

    return id == other.id &&
        storeId == other.storeId &&
        visitId == other.visitId &&
        filePath == other.filePath &&
        createdAt == other.createdAt;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return Object.hash(
      id,
      storeId,
      visitId,
      filePath,
      createdAt,
    );
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'Photo{id: $id, storeId: $storeId, visitId: $visitId, filePath: $filePath, createdAt: $createdAt}';
  }

  /// Photo エンティティをコピーして一部を変更
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
