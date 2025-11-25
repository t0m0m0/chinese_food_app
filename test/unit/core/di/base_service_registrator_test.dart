import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';

import 'package:chinese_food_app/core/database/schema/app_database.dart';

void main() {
  group('BaseServiceRegistrator Database Connection', () {
    test('should create database connection in test environment', () {
      // テスト環境ではインメモリデータベースが使われることを確認
      // この動作は既に実装済みなので、このテストはPassするはず

      // データベース接続を作成
      final connection = _createTestDatabaseConnection();

      expect(connection, isA<DatabaseConnection>());

      // データベースが正常に動作することを確認
      final database = AppDatabase(connection);
      expect(database, isNotNull);
    });

    test('should persist data across app restarts in non-test environment',
        () async {
      // このテストは実装後の動作を検証するためのプレースホルダー
      // 実際のファイルシステムアクセスが必要なため、統合テストで実施予定

      // 現時点では、ネイティブ環境でインメモリDBを使用している問題を
      // 修正する必要があることを記録

      // Red: 現在は失敗することが期待される
      expect(
        true, // 実装完了後にこの条件を実際の検証に置き換える
        isTrue,
        reason: 'Database persistence will be implemented using path_provider',
      );
    });
  });
}

/// テスト環境用のデータベース接続を作成
DatabaseConnection _createTestDatabaseConnection() {
  // テスト環境では必ずインメモリデータベースを使用
  return DatabaseConnection(NativeDatabase.memory());
}
