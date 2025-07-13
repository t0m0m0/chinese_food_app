import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web環境でのデータベース接続管理
///
/// Webブラウザでの制限事項：
/// - Native SQLiteファイルの永続化不可
/// - IndexedDBベースの実装が必要（将来対応）
/// - 現在はメモリ内データベースで動作確認
class WebDatabaseConnection {
  /// Web環境用のデータベース接続を作成
  ///
  /// 現在の実装：
  /// - メモリ内SQLite（セッション間で消失）
  /// - テスト・開発用途に適用
  ///
  /// 将来の改善予定：
  /// - IndexedDBベースの永続化
  /// - LocalStorageとの連携
  /// - オフライン対応
  static DatabaseConnection createWebConnection() {
    if (kIsWeb) {
      // Web環境: メモリ内データベース
      // 注意: ページリロードでデータが消失
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      throw UnsupportedError('WebDatabaseConnectionはWeb環境でのみ使用できます');
    }
  }

  /// Web環境でのデータベース制限事項を確認
  static Map<String, dynamic> getWebLimitations() {
    return {
      'persistent_storage': false,
      'session_only': true,
      'file_access': false,
      'indexeddb_support': false, // 将来実装予定
      'local_storage_fallback': false, // 将来実装予定
      'recommended_use': ['development', 'testing', 'demo'],
      'production_ready': false,
    };
  }
}
