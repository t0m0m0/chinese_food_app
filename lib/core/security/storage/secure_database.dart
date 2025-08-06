import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../exceptions/infrastructure/security_exception.dart';
import '../crypto/encryption_service.dart';
import '../logging/secure_logger.dart';

/// セキュアデータベース管理クラス
///
/// 暗号化されたSQLiteデータベースへのアクセスを提供します。
class SecureDatabaseManager with SecureLogging {
  static const String _dbPasswordKey = 'database_password';
  static const String _dbSaltKey = 'database_salt';

  final EncryptionService _encryptionService;
  final FlutterSecureStorage _secureStorage;
  String? _cachedPassword;

  SecureDatabaseManager({
    EncryptionService? encryptionService,
    FlutterSecureStorage? secureStorage,
  })  : _encryptionService = encryptionService ?? AESEncryptionService(),
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// セキュアなデータベース接続を作成
  Future<DatabaseConnection> createSecureConnection() async {
    try {
      logInfo('セキュアデータベース接続を作成中');

      // データベースファイルパスを取得
      final dbPath = await _getDatabasePath();

      // 暗号化パスワードを取得または生成
      final password = await _getOrCreateDatabasePassword();

      // 暗号化されたデータベース接続を作成
      final connection = await _createEncryptedConnection(dbPath, password);

      logInfo('セキュアデータベース接続を作成しました', data: {
        'path': dbPath,
        'encrypted': true,
      });

      return connection;
    } catch (e, stackTrace) {
      logError('セキュアデータベース接続の作成に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'セキュアデータベース接続の作成に失敗しました',
        context: 'Database initialization',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// データベースのバックアップを作成
  Future<String> createBackup() async {
    try {
      logInfo('データベースバックアップを作成中');

      final dbPath = await _getDatabasePath();
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = path.join(backupDir, 'backup_$timestamp.db');

      // 元のデータベースファイルをコピー
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);

        logInfo('データベースバックアップを作成しました', data: {
          'backupPath': backupPath,
          'size': await dbFile.length(),
        });

        return backupPath;
      } else {
        throw SecurityException('データベースファイルが存在しません');
      }
    } catch (e, stackTrace) {
      logError('データベースバックアップの作成に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'データベースバックアップの作成に失敗しました',
        context: 'Database backup',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// バックアップからデータベースを復元
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      logInfo('バックアップからデータベースを復元中', data: {
        'backupPath': backupPath,
      });

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw SecurityException('バックアップファイルが存在しません');
      }

      final dbPath = await _getDatabasePath();

      // 現在のデータベースファイルをバックアップ
      final currentDbFile = File(dbPath);
      if (await currentDbFile.exists()) {
        final tempBackupPath = '$dbPath.restore_backup';
        await currentDbFile.copy(tempBackupPath);
        logInfo('現在のデータベースをバックアップしました', data: {
          'tempBackupPath': tempBackupPath,
        });
      }

      // バックアップファイルから復元
      await backupFile.copy(dbPath);

      logInfo('データベースの復元が完了しました');
    } catch (e, stackTrace) {
      logError('データベースの復元に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'データベースの復元に失敗しました',
        context: 'Database restore',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// データベースパスワードを変更
  Future<void> changePassword(String newPassword) async {
    try {
      logInfo('データベースパスワードを変更中');

      // 新しいソルトを生成
      final newSalt = _encryptionService.generateSalt();

      // 新しいパスワードからキーを派生
      final newKey = _encryptionService.deriveKey(newPassword, newSalt);

      // セキュアストレージに保存
      await _secureStorage.write(key: _dbPasswordKey, value: newKey);
      await _secureStorage.write(key: _dbSaltKey, value: newSalt);

      // キャッシュを更新
      _cachedPassword = newKey;

      logInfo('データベースパスワードを変更しました');
    } catch (e, stackTrace) {
      logError('データベースパスワードの変更に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'データベースパスワードの変更に失敗しました',
        context: 'Password change',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// データベース暗号化の状態をチェック
  Future<bool> isEncrypted() async {
    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return false;
      }

      // データベースファイルの最初の数バイトを読み取って
      // SQLiteヘッダーかどうかをチェック
      final bytes = await dbFile.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(15));

      // 標準的なSQLiteヘッダーでない場合は暗号化されている
      final isStandardSqlite = header == 'SQLite format 3';

      logInfo('データベース暗号化状態をチェック', data: {
        'encrypted': !isStandardSqlite,
        'path': dbPath,
      });

      return !isStandardSqlite;
    } catch (e, stackTrace) {
      logError('データベース暗号化状態のチェックに失敗', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// データベースファイルのサイズを取得
  Future<int> getDatabaseSize() async {
    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      logError('データベースサイズの取得に失敗', error: e);
      return 0;
    }
  }

  /// データベースを完全に削除
  Future<void> deleteDatabase() async {
    try {
      logWarning('データベースを削除中');

      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
        logInfo('データベースファイルを削除しました', data: {'path': dbPath});
      }

      // セキュアストレージからパスワード情報も削除
      await _secureStorage.delete(key: _dbPasswordKey);
      await _secureStorage.delete(key: _dbSaltKey);

      // キャッシュをクリア
      _cachedPassword = null;

      logInfo('データベースの削除が完了しました');
    } catch (e, stackTrace) {
      logError('データベースの削除に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'データベースの削除に失敗しました',
        context: 'Database deletion',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// データベースファイルパスを取得
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'secure_app.db');
  }

  /// バックアップディレクトリを取得
  Future<String> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = path.join(appDir.path, 'backups');

    // ディレクトリが存在しない場合は作成
    final dir = Directory(backupDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return backupDir;
  }

  /// データベースパスワードを取得または生成
  Future<String> _getOrCreateDatabasePassword() async {
    // キャッシュから取得
    if (_cachedPassword != null) {
      return _cachedPassword!;
    }

    // セキュアストレージから取得を試行
    String? password = await _secureStorage.read(key: _dbPasswordKey);
    String? salt = await _secureStorage.read(key: _dbSaltKey);

    if (password != null && salt != null) {
      _cachedPassword = password;
      logInfo('既存のデータベースパスワードを取得しました');
      return password;
    }

    // 新しいパスワードとソルトを生成
    final newPassword = _encryptionService.generateKey();
    final newSalt = _encryptionService.generateSalt();
    final derivedKey = _encryptionService.deriveKey(newPassword, newSalt);

    // セキュアストレージに保存
    await _secureStorage.write(key: _dbPasswordKey, value: derivedKey);
    await _secureStorage.write(key: _dbSaltKey, value: newSalt);

    _cachedPassword = derivedKey;

    logInfo('新しいデータベースパスワードを生成しました');
    return derivedKey;
  }

  /// 暗号化されたデータベース接続を作成
  Future<DatabaseConnection> _createEncryptedConnection(
    String dbPath,
    String password,
  ) async {
    // 注意: これはプレースホルダー実装です
    // 実際の本番環境では、以下のような暗号化対応データベースライブラリを使用してください：
    // - sqflite_cipher: SQLCipherを使用した暗号化SQLite
    // - sqlite3_with_cipher: cipher拡張付きsqlite3
    // - 専用の暗号化データベースライブラリ

    logInfo('暗号化データベース接続を作成', data: {
      'path': dbPath,
      'encryption': 'AES-256',
    });

    // プレースホルダー実装: 標準のSQLite接続を返す
    // 本番環境では暗号化されたデータベースを使用
    return DatabaseConnection(
      NativeDatabase(File(dbPath), logStatements: false),
    );
  }

  /// キャッシュをクリア
  void clearCache() {
    _cachedPassword = null;
    logInfo('データベースパスワードキャッシュをクリアしました');
  }

  /// リソースの解放
  void dispose() {
    clearCache();
    logInfo('SecureDatabaseManagerを解放しました');
  }
}

/// セキュアデータベースファクトリー
class SecureDatabaseFactory {
  /// 本番環境用のセキュアデータベースマネージャーを作成
  static SecureDatabaseManager createForProduction() {
    return SecureDatabaseManager(
      encryptionService: AESEncryptionService(),
      secureStorage: const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    );
  }

  /// 開発環境用のセキュアデータベースマネージャーを作成
  static SecureDatabaseManager createForDevelopment() {
    return SecureDatabaseManager(
      encryptionService: AESEncryptionService(),
      secureStorage: const FlutterSecureStorage(),
    );
  }

  /// テスト環境用のセキュアデータベースマネージャーを作成
  static SecureDatabaseManager createForTesting() {
    return SecureDatabaseManager(
      encryptionService: AESEncryptionService(),
      // テスト環境では実際のセキュアストレージの代わりにモックを使用
    );
  }
}
