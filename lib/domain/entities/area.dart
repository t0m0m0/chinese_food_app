/// 都道府県を表すエンティティ
class Prefecture {
  /// 都道府県コード（例: '13' = 東京都）
  final String code;

  /// 都道府県名（例: '東京都'）
  final String name;

  const Prefecture({
    required this.code,
    required this.name,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prefecture && other.code == code && other.name == name;
  }

  @override
  int get hashCode => code.hashCode ^ name.hashCode;

  @override
  String toString() => 'Prefecture(code: $code, name: $name)';
}

/// 市区町村を表すエンティティ
class City {
  /// 所属する都道府県コード
  final String prefectureCode;

  /// 市区町村コード（例: '13101' = 千代田区）
  final String code;

  /// 市区町村名（例: '千代田区'）
  final String name;

  const City({
    required this.prefectureCode,
    required this.code,
    required this.name,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City &&
        other.prefectureCode == prefectureCode &&
        other.code == code &&
        other.name == name;
  }

  @override
  int get hashCode => prefectureCode.hashCode ^ code.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'City(prefectureCode: $prefectureCode, code: $code, name: $name)';
}

/// エリア選択状態を表すクラス
class AreaSelection {
  /// 選択された都道府県
  final Prefecture prefecture;

  /// 選択された市区町村（任意）
  final City? city;

  const AreaSelection({
    required this.prefecture,
    this.city,
  });

  /// 市区町村が選択されているかどうか
  bool get hasCity => city != null;

  /// API検索用の住所文字列を生成
  String toSearchAddress() {
    if (city != null) {
      return '${prefecture.name}${city!.name}';
    }
    return prefecture.name;
  }

  /// 表示用の名前を生成
  String get displayName {
    if (city != null) {
      return '${prefecture.name} ${city!.name}';
    }
    return prefecture.name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaSelection &&
        other.prefecture == prefecture &&
        other.city == city;
  }

  @override
  int get hashCode => prefecture.hashCode ^ city.hashCode;

  @override
  String toString() => 'AreaSelection(prefecture: $prefecture, city: $city)';
}
