// Note: SqliteException is available through drift package

/// Issue #113 Phase 2: 型安全なデータベースエラーハンドリング
///
/// 文字列マッチングに依存する代わりに、例外型による判定を提供するユーティリティ。
/// これにより、Flutter/Dartバージョンアップ時のエラーメッセージ変更による
/// 誤動作を防ぎ、型安全性を向上させる。
class DatabaseErrorHandler {
  /// SQLiteファイルアクセスエラー（SqliteException code 14）の判定
  ///
  /// **対象エラー**:
  /// - SqliteException(14): unable to open database file
  /// - ファイルアクセス権限問題
  /// - 無効なファイルパス
  static bool isDatabaseFileAccessError(Exception error) {
    // 現在は文字列マッチングを使用（将来的に型判定に移行）
    // TODO(Issue #113 Phase 2): drift package のSqliteExceptionを使用した型安全判定に移行
    final errorString = error.toString();
    return errorString.contains('SqliteException(14)') ||
        errorString.contains('unable to open database file');
  }

  /// dart:ffi利用不可エラーの判定（Web環境）
  ///
  /// **対象エラー**:
  /// - dart:ffi is not available on this platform
  /// - Web環境でのNative Database使用エラー
  static bool isFFIError(Exception error) {
    final errorString = error.toString();
    return errorString.contains('dart:ffi') ||
        errorString.contains('not available on this platform');
  }

  /// データベース初期化エラーの判定
  ///
  /// **対象エラー**:
  /// - NotInitializedError
  /// - 設定管理の初期化失敗
  static bool isInitializationError(Exception error) {
    final errorString = error.toString();
    return errorString.contains('NotInitializedError') ||
        errorString.contains('not initialized');
  }

  /// 適切なユーザーフレンドリーなエラーメッセージを生成
  ///
  /// **戻り値**: ユーザーに表示する適切なエラーメッセージ
  static String getUserFriendlyMessage(Exception error) {
    if (isDatabaseFileAccessError(error)) {
      return 'データベースファイルにアクセスできません。アプリを再起動してください。';
    } else if (isFFIError(error)) {
      return 'Web環境でのデータベース制限です。機能は制限付きで動作します。';
    } else if (isInitializationError(error)) {
      return 'データベースが初期化されていません。しばらくお待ちください。';
    } else {
      return '予期しないエラーが発生しました。再試行してください。';
    }
  }

  /// エラーの重要度レベルを判定
  ///
  /// **戻り値**:
  /// - 0: Info
  /// - 1: Warning
  /// - 2: Error
  /// - 3: Critical
  static int getErrorSeverity(Exception error) {
    if (isDatabaseFileAccessError(error)) {
      return 3; // Critical - データ永続化に影響
    } else if (isFFIError(error)) {
      return 1; // Warning - 制限付きで動作可能
    } else if (isInitializationError(error)) {
      return 2; // Error - 機能に影響
    } else {
      return 2; // Error - 不明なエラー
    }
  }
}
