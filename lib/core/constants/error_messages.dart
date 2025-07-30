/// QA改善: エラーメッセージの国際化対応
///
/// 将来的な多言語展開を見据えた構造化エラーメッセージ定義
/// セキュリティ関連エラーの統一的な管理を提供
class ErrorMessages {
  // 言語設定（将来的に動的切り替え対応）
  static const String _currentLanguage = 'ja'; // 'ja', 'en' 対応予定

  /// セキュリティ関連エラーメッセージ
  static const Map<String, Map<String, String>> _securityMessages = {
    'sql_injection_detected': {
      'ja': 'セキュリティ上の理由により、この検索は実行できません',
      'en': 'This search cannot be executed for security reasons',
    },
    'invalid_input_format': {
      'ja': '入力形式が正しくありません',
      'en': 'Invalid input format',
    },
    'api_key_missing': {
      'ja': 'API設定に問題があります。管理者にお問い合わせください',
      'en': 'API configuration issue. Please contact administrator',
    },
    'unauthorized_access': {
      'ja': 'アクセスが拒否されました',
      'en': 'Access denied',
    },
    'rate_limit_exceeded': {
      'ja': 'リクエストが集中しています。しばらく時間をおいてからお試しください',
      'en': 'Rate limit exceeded. Please try again later',
    },
  };

  /// データベース関連エラーメッセージ
  static const Map<String, Map<String, String>> _databaseMessages = {
    'store_not_found': {
      'ja': '店舗が見つかりません',
      'en': 'Store not found',
    },
    'transaction_failed': {
      'ja': 'データの保存に失敗しました。もう一度お試しください',
      'en': 'Failed to save data. Please try again',
    },
    'duplicate_store': {
      'ja': 'この店舗は既に登録されています',
      'en': 'This store is already registered',
    },
    'database_connection_error': {
      'ja': 'データベースに接続できませんでした',
      'en': 'Database connection failed',
    },
  };

  /// 一般的なエラーメッセージ
  static const Map<String, Map<String, String>> _generalMessages = {
    'network_error': {
      'ja': 'ネットワークエラーが発生しました。接続を確認してください',
      'en': 'Network error occurred. Please check your connection',
    },
    'timeout_error': {
      'ja': 'タイムアウトしました。もう一度お試しください',
      'en': 'Request timed out. Please try again',
    },
    'unknown_error': {
      'ja': '予期しないエラーが発生しました',
      'en': 'An unexpected error occurred',
    },
    'validation_error': {
      'ja': '入力値を確認してください',
      'en': 'Please check your input',
    },
  };

  /// セキュリティエラーメッセージ取得
  static String getSecurityMessage(String key) {
    return _getMessage(_securityMessages, key);
  }

  /// データベースエラーメッセージ取得
  static String getDatabaseMessage(String key) {
    return _getMessage(_databaseMessages, key);
  }

  /// 一般エラーメッセージ取得
  static String getGeneralMessage(String key) {
    return _getMessage(_generalMessages, key);
  }

  /// 内部メソッド：言語設定に基づくメッセージ取得
  static String _getMessage(
      Map<String, Map<String, String>> messages, String key) {
    final messageMap = messages[key];
    if (messageMap == null) {
      // デバッグ用：未定義キーの場合
      return 'Error message not found: $key';
    }

    // 現在の言語設定でメッセージを取得、存在しない場合は日本語をフォールバック
    return messageMap[_currentLanguage] ??
        messageMap['ja'] ??
        'Unknown error: $key';
  }

  /// 将来的な動的言語切り替え用（現在は固定）
  ///
  /// 使用例:
  /// ```dart
  /// ErrorMessages.setLanguage('en');
  /// final message = ErrorMessages.getSecurityMessage('sql_injection_detected');
  /// ```
  static String get currentLanguage => _currentLanguage;

  /// サポート言語一覧
  static const List<String> supportedLanguages = ['ja', 'en'];

  /// デバッグ用：全エラーメッセージのキー一覧取得
  static List<String> getAllMessageKeys() {
    final allKeys = <String>[];
    allKeys.addAll(_securityMessages.keys);
    allKeys.addAll(_databaseMessages.keys);
    allKeys.addAll(_generalMessages.keys);
    return allKeys;
  }
}
