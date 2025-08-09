// Note: SqliteExceptionのインポート は将来の段階的改善で追加予定

/// Issue #113 Phase 2: 型安全なデータベースエラーハンドリング
///
/// 文字列マッチングに依存する代わりに、例外型による判定を提供するユーティリティ。
/// これにより、Flutter/Dartバージョンアップ時のエラーメッセージ変更による
/// 誤動作を防ぎ、型安全性を向上させる。
class DatabaseErrorHandler {
  // エラー重要度定数の定義
  static const int severityInfo = 0;
  static const int severityWarning = 1;
  static const int severityError = 2;
  static const int severityCritical = 3;

  /// SQLiteファイルアクセスエラー（SqliteException code 14）の判定
  ///
  /// **対象エラー**:
  /// - SqliteException(14): unable to open database file (SQLITE_CANTOPEN)
  /// - ファイルアクセス権限問題
  /// - 無効なファイルパス
  static bool isDatabaseFileAccessError(Exception error) {
    // 改善された文字列マッチング（現在の実装）
    // TODO(Issue #113 Phase 2 by 2025-09-01): sqlite3パッケージのSqliteException型チェックに移行
    final errorString = error.toString();

    // より精密なエラーパターンマッチング
    return _matchesDatabaseFileError(errorString);
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
  /// - severityInfo (0): Info
  /// - severityWarning (1): Warning
  /// - severityError (2): Error
  /// - severityCritical (3): Critical
  static int getErrorSeverity(Exception error) {
    if (isDatabaseFileAccessError(error)) {
      return severityCritical; // Critical - データ永続化に影響
    } else if (isFFIError(error)) {
      return severityWarning; // Warning - 制限付きで動作可能
    } else if (isInitializationError(error)) {
      return severityError; // Error - 機能に影響
    } else {
      return severityError; // Error - 不明なエラー
    }
  }

  /// データベースファイルアクセスエラーのパターンマッチング
  static bool _matchesDatabaseFileError(String errorString) {
    // SQLITE_CANTOPEN (14) エラーの様々なパターン
    final patterns = [
      'SqliteException(14)',
      'unable to open database file',
      'database disk image is malformed',
      'database is locked',
      'SQLITE_CANTOPEN',
    ];

    return patterns.any((pattern) => errorString.contains(pattern));
  }
}
