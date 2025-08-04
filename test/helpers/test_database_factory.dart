import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';

/// テスト用データベースファクトリークラス
///
/// Driftの警告を避けるため、テストでのデータベースインスタンス作成を統一管理
class TestDatabaseFactory {
  static bool _isWarningDisabled = false;

  /// テスト用のインメモリデータベースを作成
  ///
  /// 初回呼び出し時にDriftの警告を無効化
  static AppDatabase createTestDatabase() {
    _ensureWarningDisabled();
    return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  }

  /// テスト用のファイルベースデータベースを作成
  ///
  /// [path] データベースファイルのパス
  static AppDatabase createTestDatabaseWithFile(String path) {
    _ensureWarningDisabled();
    return AppDatabase(DatabaseConnection(NativeDatabase(File(path))));
  }

  /// Drift警告を無効化（一度だけ実行）
  static void _ensureWarningDisabled() {
    if (!_isWarningDisabled) {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _isWarningDisabled = true;
    }
  }

  /// テスト環境で安全にデータベースを破棄
  ///
  /// [database] 破棄するデータベースインスタンス
  static Future<void> disposeTestDatabase(AppDatabase database) async {
    try {
      await database.close();
    } catch (e) {
      // エラーは無視（テスト環境での破棄エラーは通常無害）
    }
  }
}
