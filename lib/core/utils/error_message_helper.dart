/// ユーザーフレンドリーなエラーメッセージを生成するヘルパークラス
///
/// 技術的なエラーメッセージを、エンドユーザーが理解しやすい
/// 日本語のメッセージに変換する
class ErrorMessageHelper {
  /// 技術的なエラーをユーザーフレンドリーなメッセージに変換
  ///
  /// [error] 発生した例外やエラーオブジェクト
  /// 戻り値: ユーザーが理解しやすい日本語のエラーメッセージ
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return '予期しないエラーが発生しました';

    final errorString = error.toString().toLowerCase();

    // ネットワーク関連エラー
    if (_isNetworkError(errorString)) {
      return 'ネットワークに接続できません。接続を確認してから再試行してください。';
    }

    // データベース関連エラー
    if (_isDatabaseError(errorString)) {
      return 'データの保存に失敗しました。しばらくしてから再試行してください。';
    }

    // タイムアウトエラー
    if (_isTimeoutError(errorString)) {
      return '処理がタイムアウトしました。再試行してください。';
    }

    // API関連エラー
    if (_isApiError(errorString)) {
      return 'サーバーとの通信に失敗しました。しばらくしてから再試行してください。';
    }

    // 認証エラー
    if (_isAuthError(errorString)) {
      return '認証に失敗しました。設定を確認してください。';
    }

    // 権限エラー
    if (_isPermissionError(errorString)) {
      return '必要な権限がありません。アプリの設定を確認してください。';
    }

    // ストレージエラー
    if (_isStorageError(errorString)) {
      return 'ストレージの容量が不足している可能性があります。';
    }

    // 位置情報エラー
    if (_isLocationError(errorString)) {
      return '位置情報の取得に失敗しました。位置情報サービスを有効にしてください。';
    }

    // その他の一般的なエラー
    return '予期しないエラーが発生しました。再試行してください。';
  }

  /// ネットワーク関連エラーの判定
  static bool _isNetworkError(String errorString) {
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('internet') ||
        errorString.contains('socket') ||
        errorString.contains('unreachable') ||
        errorString.contains('offline');
  }

  /// データベース関連エラーの判定
  static bool _isDatabaseError(String errorString) {
    return errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('sqlite') ||
        errorString.contains('table') ||
        errorString.contains('constraint') ||
        errorString.contains('foreign key');
  }

  /// タイムアウトエラーの判定
  static bool _isTimeoutError(String errorString) {
    return errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('deadline');
  }

  /// API関連エラーの判定
  static bool _isApiError(String errorString) {
    return errorString.contains('api') ||
        errorString.contains('server') ||
        errorString.contains('http') ||
        errorString.contains('response') ||
        errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503');
  }

  /// 認証エラーの判定
  static bool _isAuthError(String errorString) {
    return errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('credential') ||
        errorString.contains('token') ||
        errorString.contains('login');
  }

  /// 権限エラーの判定
  static bool _isPermissionError(String errorString) {
    return errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access denied') ||
        errorString.contains('privilege');
  }

  /// ストレージエラーの判定
  static bool _isStorageError(String errorString) {
    return errorString.contains('storage') ||
        errorString.contains('disk') ||
        errorString.contains('space') ||
        errorString.contains('memory') ||
        errorString.contains('full');
  }

  /// 位置情報エラーの判定
  static bool _isLocationError(String errorString) {
    return errorString.contains('location') ||
        errorString.contains('gps') ||
        errorString.contains('geolocation') ||
        errorString.contains('position');
  }

  /// 特定の業務エラーメッセージの生成
  ///
  /// アプリ固有のエラー状況に対するメッセージ
  static String getStoreRelatedMessage(String operation) {
    switch (operation.toLowerCase()) {
      case 'update_status':
        return '店舗のステータス更新に失敗しました。再試行してください。';
      case 'add_store':
        return '店舗の追加に失敗しました。再試行してください。';
      case 'load_stores':
        return '店舗データの読み込みに失敗しました。再試行してください。';
      case 'search_stores':
        return '店舗の検索に失敗しました。検索条件を変更して再試行してください。';
      case 'duplicate_store':
        return 'この店舗は既に登録されています。';
      default:
        return '店舗関連の処理に失敗しました。再試行してください。';
    }
  }
}
