import '../search_config.dart';

/// 検索設定管理を担当するManager
class SearchConfigManager {
  SearchConfigManager._(); // private constructor

  /// 検索設定の検証を実行
  static List<String> validate() {
    final errors = <String>[];

    if (!SearchConfig.isValidRange(SearchConfig.defaultRange)) {
      errors.add('検索範囲が無効です: ${SearchConfig.defaultRange}');
    }

    if (!SearchConfig.isValidCount(SearchConfig.defaultCount)) {
      errors.add('検索結果数が無効です: ${SearchConfig.defaultCount}');
    }

    if (!SearchConfig.isValidKeyword(SearchConfig.defaultKeyword)) {
      errors.add('検索キーワードが無効です: ${SearchConfig.defaultKeyword}');
    }

    return errors;
  }

  /// 検索設定情報を取得
  static Map<String, dynamic> getConfig() {
    return {
      'type': 'search',
      'range': SearchConfig.defaultRange,
      'count': SearchConfig.defaultCount,
      'keyword': SearchConfig.defaultKeyword,
      'pageSize': SearchConfig.defaultPageSize,
      'start': SearchConfig.defaultStart,
    };
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'manager': 'SearchConfigManager',
      'config': getConfig(),
      'validationErrors': validate(),
    };
  }
}