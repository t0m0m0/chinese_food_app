/// Centralized information message management for consistent user experience
///
/// This class provides a single source of truth for all informational messages
/// displayed to users throughout the application.
class InfoMessages {
  InfoMessages._();

  /// 店舗関連情報メッセージ
  static const Map<String, Map<String, String>> _storeMessages = {
    'no_stores_found_nearby': {
      'ja': '現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。',
      'en':
          'No new Chinese restaurants found nearby. Try expanding the search range.',
    },
    'all_stores_reviewed': {
      'ja': 'すべての店舗を確認済みです！検索画面で新しい店舗を探してみましょう',
      'en': 'All stores have been reviewed! Try searching for new stores.',
    },
    'stores_loaded_successfully': {
      'ja': '店舗データを読み込みました',
      'en': 'Store data loaded successfully',
    },
    'store_status_updated': {
      'ja': '店舗ステータスを更新しました',
      'en': 'Store status updated successfully',
    },
    'store_added_successfully': {
      'ja': '店舗を追加しました',
      'en': 'Store added successfully',
    },
  };

  /// 検索関連情報メッセージ
  static const Map<String, Map<String, String>> _searchMessages = {
    'search_completed': {
      'ja': '検索が完了しました',
      'en': 'Search completed',
    },
    'no_search_results': {
      'ja': '検索結果が見つかりませんでした',
      'en': 'No search results found',
    },
    'search_range_expanded': {
      'ja': '検索範囲を拡大しました',
      'en': 'Search range expanded',
    },
  };

  /// 位置情報関連情報メッセージ
  static const Map<String, Map<String, String>> _locationMessages = {
    'location_obtained': {
      'ja': '現在地を取得しました',
      'en': 'Current location obtained',
    },
    'using_default_location': {
      'ja': 'デフォルト位置を使用しています',
      'en': 'Using default location',
    },
    'location_permission_granted': {
      'ja': '位置情報の権限が許可されました',
      'en': 'Location permission granted',
    },
  };

  // 言語設定（将来的に動的切り替え対応）
  static const String _currentLanguage = 'ja'; // 'ja', 'en' 対応予定

  /// 店舗情報メッセージ取得
  static String getStoreMessage(String key) {
    return _getMessage(_storeMessages, key);
  }

  /// 検索情報メッセージ取得
  static String getSearchMessage(String key) {
    return _getMessage(_searchMessages, key);
  }

  /// 位置情報メッセージ取得
  static String getLocationMessage(String key) {
    return _getMessage(_locationMessages, key);
  }

  /// 内部メソッド：言語設定に基づくメッセージ取得
  static String _getMessage(
      Map<String, Map<String, String>> messages, String key) {
    final messageMap = messages[key];
    if (messageMap == null) {
      // デバッグ用：未定義キーの場合
      return 'Info message not found: $key';
    }

    // 現在の言語設定でメッセージを取得、存在しない場合は日本語をフォールバック
    return messageMap[_currentLanguage] ??
        messageMap['ja'] ??
        'Unknown info: $key';
  }

  /// コンテキスト付きメッセージ生成
  static String withContext(String baseMessage, String context) {
    return '$baseMessage（$context）';
  }

  /// 数値付きメッセージ生成
  static String withCount(String baseMessage, int count) {
    return '$baseMessage ($count件)';
  }

  /// サポート言語一覧
  static const List<String> supportedLanguages = ['ja', 'en'];

  /// デバッグ用：全情報メッセージのキー一覧取得
  static List<String> getAllMessageKeys() {
    final allKeys = <String>[];
    allKeys.addAll(_storeMessages.keys);
    allKeys.addAll(_searchMessages.keys);
    allKeys.addAll(_locationMessages.keys);
    return allKeys;
  }
}
