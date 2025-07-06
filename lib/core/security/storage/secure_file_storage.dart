import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../errors/security_exceptions.dart';
import '../crypto/encryption_service.dart';
import '../logging/secure_logger.dart';

/// セキュアファイルストレージ
///
/// 写真やその他の機密ファイルを暗号化して安全に保存します。
class SecureFileStorage with SecureLogging {
  final EncryptionService _encryptionService;
  final String _storageKey;

  SecureFileStorage({
    EncryptionService? encryptionService,
    String? storageKey,
  })  : _encryptionService = encryptionService ?? AESEncryptionService(),
        _storageKey = storageKey ?? 'default_storage_key';

  /// ファイルを暗号化して保存
  Future<String> saveEncryptedFile(
    Uint8List fileData,
    String fileName, {
    String? customPath,
    Map<String, String>? metadata,
  }) async {
    try {
      logInfo('ファイルを暗号化して保存中', data: {
        'fileName': fileName,
        'size': fileData.length,
      });

      // 保存先ディレクトリを確保
      final storageDir = await _getSecureStorageDirectory(customPath);

      // ファイル名をサニタイズ
      final sanitizedFileName = _sanitizeFileName(fileName);

      // 暗号化キーを生成
      final encryptionKey = _generateFileKey(fileName);

      // ファイルデータを暗号化
      final encryptedData = await _encryptionService.encryptBytes(
        fileData,
        encryptionKey,
      );

      // メタデータを作成
      final fileMetadata = _createFileMetadata(
        originalFileName: fileName,
        encryptedFileName: sanitizedFileName,
        originalSize: fileData.length,
        encryptedSize: encryptedData.length,
        customMetadata: metadata,
      );

      // 暗号化されたファイルを保存
      final encryptedFilePath = path.join(storageDir, '$sanitizedFileName.enc');
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedData);

      // メタデータファイルを保存
      final metadataPath = path.join(storageDir, '$sanitizedFileName.meta');
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(fileMetadata));

      logInfo('ファイルの暗号化保存が完了', data: {
        'encryptedPath': encryptedFilePath,
        'metadataPath': metadataPath,
      });

      return encryptedFilePath;
    } catch (e, stackTrace) {
      logError('ファイルの暗号化保存に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'ファイルの暗号化保存に失敗しました',
        context: 'File encryption and storage',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 暗号化されたファイルを復号化して読み込み
  Future<Uint8List> loadEncryptedFile(String encryptedFilePath) async {
    try {
      logInfo('暗号化ファイルを復号化して読み込み中', data: {
        'path': encryptedFilePath,
      });

      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw SecurityException('暗号化ファイルが存在しません');
      }

      // メタデータを読み込み
      final metadata = await _loadFileMetadata(encryptedFilePath);
      final originalFileName = metadata['originalFileName'] as String;

      // 暗号化キーを生成
      final encryptionKey = _generateFileKey(originalFileName);

      // 暗号化ファイルを読み込み
      final encryptedData = await encryptedFile.readAsBytes();

      // ファイルデータを復号化
      final decryptedData = await _encryptionService.decryptBytes(
        encryptedData,
        encryptionKey,
      );

      logInfo('ファイルの復号化読み込みが完了', data: {
        'originalSize': decryptedData.length,
      });

      return decryptedData;
    } catch (e, stackTrace) {
      logError('ファイルの復号化読み込みに失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'ファイルの復号化読み込みに失敗しました',
        context: 'File decryption and loading',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ファイルのメタデータを取得
  Future<Map<String, dynamic>> getFileMetadata(String encryptedFilePath) async {
    try {
      return await _loadFileMetadata(encryptedFilePath);
    } catch (e, stackTrace) {
      logError('ファイルメタデータの取得に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'ファイルメタデータの取得に失敗しました',
        context: 'Metadata loading',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 保存されているすべての暗号化ファイルを一覧取得
  Future<List<String>> listEncryptedFiles({String? customPath}) async {
    try {
      logInfo('暗号化ファイル一覧を取得中');

      final storageDir = await _getSecureStorageDirectory(customPath);
      final directory = Directory(storageDir);

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.enc'))
          .cast<File>()
          .map((file) => file.path)
          .toList();

      logInfo('暗号化ファイル一覧を取得', data: {
        'count': files.length,
      });

      return files;
    } catch (e, stackTrace) {
      logError('暗号化ファイル一覧の取得に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        '暗号化ファイル一覧の取得に失敗しました',
        context: 'File listing',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 暗号化ファイルを削除
  Future<void> deleteEncryptedFile(String encryptedFilePath) async {
    try {
      logInfo('暗号化ファイルを削除中', data: {
        'path': encryptedFilePath,
      });

      final encryptedFile = File(encryptedFilePath);
      if (await encryptedFile.exists()) {
        await encryptedFile.delete();
      }

      // メタデータファイルも削除
      final metadataPath = encryptedFilePath.replaceAll('.enc', '.meta');
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      logInfo('暗号化ファイルの削除が完了');
    } catch (e, stackTrace) {
      logError('暗号化ファイルの削除に失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        '暗号化ファイルの削除に失敗しました',
        context: 'File deletion',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ファイルの整合性をチェック
  Future<bool> verifyFileIntegrity(String encryptedFilePath) async {
    try {
      logInfo('ファイル整合性をチェック中', data: {
        'path': encryptedFilePath,
      });

      // メタデータを読み込み
      final metadata = await _loadFileMetadata(encryptedFilePath);
      final expectedHash = metadata['checksum'] as String?;

      if (expectedHash == null) {
        logWarning('ファイルにチェックサムが設定されていません');
        return false;
      }

      // 実際のファイルのハッシュを計算
      final encryptedFile = File(encryptedFilePath);
      final fileData = await encryptedFile.readAsBytes();
      final actualHash = sha256.convert(fileData).toString();

      final isValid = expectedHash == actualHash;

      logInfo('ファイル整合性チェック完了', data: {
        'valid': isValid,
      });

      return isValid;
    } catch (e, stackTrace) {
      logError('ファイル整合性チェックに失敗', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// ストレージの使用量を取得
  Future<int> getStorageUsage({String? customPath}) async {
    try {
      final storageDir = await _getSecureStorageDirectory(customPath);
      final directory = Directory(storageDir);

      if (!await directory.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      logInfo('ストレージ使用量を取得', data: {
        'usage': totalSize,
        'path': storageDir,
      });

      return totalSize;
    } catch (e, stackTrace) {
      logError('ストレージ使用量の取得に失敗', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// 古いファイルをクリーンアップ
  Future<void> cleanupOldFiles({
    Duration? maxAge,
    String? customPath,
  }) async {
    try {
      final maxAgeLimit = maxAge ?? const Duration(days: 30);
      final cutoffTime = DateTime.now().subtract(maxAgeLimit);

      logInfo('古いファイルのクリーンアップを開始', data: {
        'maxAge': maxAgeLimit.inDays,
      });

      final files = await listEncryptedFiles(customPath: customPath);
      int deletedCount = 0;

      for (final filePath in files) {
        try {
          final metadata = await _loadFileMetadata(filePath);
          final createdAt = DateTime.parse(metadata['createdAt'] as String);

          if (createdAt.isBefore(cutoffTime)) {
            await deleteEncryptedFile(filePath);
            deletedCount++;
          }
        } catch (e) {
          logWarning('ファイルのクリーンアップ中にエラー', error: e, data: {
            'filePath': filePath,
          });
        }
      }

      logInfo('古いファイルのクリーンアップが完了', data: {
        'deletedCount': deletedCount,
      });
    } catch (e, stackTrace) {
      logError('ファイルクリーンアップに失敗', error: e, stackTrace: stackTrace);

      throw SecurityException(
        'ファイルクリーンアップに失敗しました',
        context: 'File cleanup',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// セキュアストレージディレクトリを取得
  Future<String> _getSecureStorageDirectory(String? customPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = customPath != null
        ? path.join(appDir.path, customPath)
        : path.join(appDir.path, 'secure_storage');

    // ディレクトリが存在しない場合は作成
    final dir = Directory(storageDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return storageDir;
  }

  /// ファイル名をサニタイズ
  String _sanitizeFileName(String fileName) {
    // 入力値検証：空文字・NULL・不正値チェック
    if (fileName.isEmpty) {
      throw SecurityException('ファイル名が空です');
    }

    // セキュリティ対策: パストラバーサル攻撃防止
    String sanitized = fileName
        .replaceAll(RegExp(r'\.\.'), '') // ディレクトリトラバーサル防止
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // 危険文字の除去
        .replaceAll(RegExp(r'\s+'), '_') // 空白文字の正規化
        .replaceAll(RegExp(r'\0'), '') // NULLバイト攻撃防止
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ''); // 制御文字除去

    // 予約語・危険なファイル名の回避
    final reservedNames = {
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9'
    };

    final nameWithoutExt =
        path.basenameWithoutExtension(sanitized).toUpperCase();
    if (reservedNames.contains(nameWithoutExt)) {
      sanitized = 'safe_$sanitized';
    }

    // 絶対パスや相対パス記号の除去
    sanitized = sanitized.replaceAll(RegExp(r'^[/\\]+'), '');
    sanitized = sanitized.replaceAll(RegExp(r'^\.'), 'dot_');

    // 最終検証：空になった場合のフォールバック
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = 'fallback_file';
    }

    // 長すぎる場合は切り詰め（セキュアに）
    if (sanitized.length > 100) {
      final extension = path.extension(sanitized);
      final nameWithoutExtension = path.basenameWithoutExtension(sanitized);
      final maxNameLength = 100 - extension.length - 10; // 余裕を持たせる
      if (maxNameLength > 0) {
        sanitized =
            '${nameWithoutExtension.substring(0, maxNameLength)}$extension';
      } else {
        sanitized = 'truncated${extension.isNotEmpty ? extension : '.safe'}';
      }
    }

    // タイムスタンプを追加してユニーク性を確保
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameWithoutExtension = path.basenameWithoutExtension(sanitized);
    final extension = path.extension(sanitized);

    final finalName = '${nameWithoutExtension}_$timestamp$extension';

    // 最終的なセキュリティ検証
    if (_isSecureFileName(finalName)) {
      return finalName;
    } else {
      throw SecurityException('ファイル名のサニタイズに失敗しました: 安全でない文字が残存');
    }
  }

  /// ファイル名が安全かどうかを検証
  bool _isSecureFileName(String fileName) {
    // 危険な文字パターンの最終チェック
    final dangerousPatterns = [
      RegExp(r'\.\.'), // ディレクトリトラバーサル
      RegExp(r'[<>:"/\\|?*]'), // 危険文字
      RegExp(r'\0'), // NULLバイト
      RegExp(r'[\x00-\x1f\x7f]'), // 制御文字
      RegExp(r'^\.'), // 隠しファイル（先頭ドット）
      RegExp(r'^[/\\]'), // 絶対パス
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(fileName)) {
        return false;
      }
    }

    // 長さチェック
    if (fileName.isEmpty || fileName.length > 200) {
      return false;
    }

    return true;
  }

  /// ファイル暗号化キーを生成
  String _generateFileKey(String fileName) {
    final combined = '$_storageKey:$fileName';
    return _encryptionService.hashData(combined);
  }

  /// ファイルメタデータを作成
  Map<String, dynamic> _createFileMetadata({
    required String originalFileName,
    required String encryptedFileName,
    required int originalSize,
    required int encryptedSize,
    Map<String, String>? customMetadata,
  }) {
    final metadata = <String, dynamic>{
      'originalFileName': originalFileName,
      'encryptedFileName': encryptedFileName,
      'originalSize': originalSize,
      'encryptedSize': encryptedSize,
      'createdAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    if (customMetadata != null) {
      metadata['custom'] = customMetadata;
    }

    return metadata;
  }

  /// ファイルメタデータを読み込み
  Future<Map<String, dynamic>> _loadFileMetadata(
      String encryptedFilePath) async {
    final metadataPath = encryptedFilePath.replaceAll('.enc', '.meta');
    final metadataFile = File(metadataPath);

    if (!await metadataFile.exists()) {
      throw SecurityException('メタデータファイルが存在しません');
    }

    final metadataJson = await metadataFile.readAsString();
    return jsonDecode(metadataJson) as Map<String, dynamic>;
  }
}

/// セキュアファイルストレージファクトリー
class SecureFileStorageFactory {
  /// 写真用のセキュアストレージを作成
  static SecureFileStorage createForPhotos() {
    return SecureFileStorage(
      encryptionService: AESEncryptionService(),
      storageKey: 'photo_storage_key',
    );
  }

  /// ドキュメント用のセキュアストレージを作成
  static SecureFileStorage createForDocuments() {
    return SecureFileStorage(
      encryptionService: AESEncryptionService(),
      storageKey: 'document_storage_key',
    );
  }

  /// カスタム用途のセキュアストレージを作成
  static SecureFileStorage createCustom(String storageKey) {
    return SecureFileStorage(
      encryptionService: AESEncryptionService(),
      storageKey: storageKey,
    );
  }

  /// テスト用のセキュアストレージを作成
  static SecureFileStorage createForTesting() {
    return SecureFileStorage(
      encryptionService: AESEncryptionService(),
      storageKey: 'test_storage_key',
    );
  }
}
