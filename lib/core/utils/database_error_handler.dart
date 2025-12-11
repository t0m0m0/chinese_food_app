import 'package:sqlite3/sqlite3.dart';

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

  /// SQLite関連エラーコード
  /// https://www.sqlite.org/rescode.html
  static const int sqliteIoErr = 10; // SQLITE_IOERR
  static const int sqliteCorrupt = 11; // SQLITE_CORRUPT
  static const int sqliteCantOpen = 14; // SQLITE_CANTOPEN
  static const int sqliteBusy = 5; // SQLITE_BUSY

  /// データベースアクセスエラーに該当するSQLiteエラーコード一覧
  static const List<int> _databaseAccessErrorCodes = [
    sqliteIoErr, // 10: disk I/O error
    sqliteCorrupt, // 11: database disk image is malformed
    sqliteCantOpen, // 14: unable to open database file
    sqliteBusy, // 5: database is locked
  ];

  /// SQLiteファイルアクセスエラーの判定
  ///
  /// **対象エラー**:
  /// - SqliteException(14): unable to open database file (SQLITE_CANTOPEN)
  /// - SqliteException(5): database is locked (SQLITE_BUSY)
  /// - SqliteException(10): disk I/O error (SQLITE_IOERR)
  /// - SqliteException(11): database disk image is malformed (SQLITE_CORRUPT)
  /// - その他のファイルアクセス関連例外
  ///
  /// SqliteException型の場合は型チェックとエラーコードで判定し、
  /// それ以外の例外は文字列マッチングにフォールバックします。
  static bool isDatabaseFileAccessError(Exception error) {
    // SqliteException型の場合は型安全な判定を行う
    if (error is SqliteException) {
      return _databaseAccessErrorCodes.contains(error.extendedResultCode) ||
          _databaseAccessErrorCodes.contains(error.resultCode);
    }

    // その他の例外は文字列マッチングにフォールバック
    final errorString = error.toString();
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

  /// sqlite3パッケージのSqliteException型チェックがサポートされているかを確認
  ///
  /// Issue #113 Phase 2: 型安全性向上のためのサポート確認
  /// 現在は未実装のため、常にtrueを返します（将来の実装のための基盤）
  static bool supportsSqliteExceptionTypeCheck() {
    // 将来的にはsqlite3パッケージの利用可能性をチェック
    return true; // 基盤実装として常にtrueを返す
  }

  /// 型安全なデータベースエラーハンドラーを作成
  ///
  /// Issue #113 Phase 2: sqlite3パッケージのSqliteExceptionを使用した
  /// 型安全なエラー処理の実装
  /// 現在は未実装のため、UnimplementedErrorを投げます
  static TypedDatabaseErrorHandler createTypedHandler() {
    throw UnimplementedError(
        'Typed database error handler not yet implemented');
  }

  /// 多言語対応エラーメッセージを取得
  ///
  /// Issue #113 Phase 2: エラーメッセージの多言語化
  /// 現在は未実装のため、UnimplementedErrorを投げます
  static Map<String, String> getLocalizedErrorMessages() {
    throw UnimplementedError('Localized error messages not yet implemented');
  }

  /// データベースファイルアクセスエラーのパターンマッチング
  static bool _matchesDatabaseFileError(String errorString) {
    // SQLITE_CANTOPEN (14) エラーの様々なパターン
    final patterns = [
      'SqliteException(14)',
      'unable to open database file',
      'cannot open database file',
      'database disk image is malformed',
      'database is locked',
      'SQLITE_CANTOPEN',
      'disk I/O error',
    ];

    return patterns.any((pattern) => errorString.contains(pattern));
  }
}

/// 型安全なデータベースエラーハンドラー（Issue #113 Phase 2）
///
/// sqlite3パッケージのSqliteExceptionを使用した型安全なエラー処理を提供します。
/// 現在は基盤実装のため、実際の型チェックは未実装です。
abstract class TypedDatabaseErrorHandler {
  /// データベースファイルアクセスエラーの型安全な判定
  bool get isDatabaseFileAccessError;

  /// FFIエラーの型安全な判定
  bool get isFFIError;

  /// 初期化エラーの型安全な判定
  bool get isInitializationError;

  /// ユーザーフレンドリーなエラーメッセージの生成
  String get userFriendlyMessage;

  /// エラーの重要度レベル
  int get errorSeverity;
}
