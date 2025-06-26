import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// アプリケーション設定管理クラス
///
/// 環境変数やAPIキーなどの機密情報を安全に管理します。
/// 本番環境では flutter_secure_storage を使用して機密情報を保護します。
class AppConfig {
  // テスト用のAPIキー保存
  static String? _testHotpepperApiKey;
  static String? _testGoogleMapsApiKey;
  
  // セキュアストレージのインスタンス
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// ホットペッパーAPIキー
  ///
  /// テスト環境: テスト用APIキーを使用
  /// 本番環境: flutter_secure_storage から取得
  /// 開発環境: 環境変数から取得
  static Future<String?> get hotpepperApiKey async {
    // テスト環境ではテスト用APIキーを使用
    if (_testHotpepperApiKey != null) {
      return _testHotpepperApiKey;
    }
    
    // 本番環境では secure_storage を使用
    if (isProduction) {
      try {
        return await _storage.read(key: 'HOTPEPPER_API_KEY');
      } catch (e) {
        return null;
      }
    }
    
    // 開発環境では環境変数から取得
    return const String.fromEnvironment('HOTPEPPER_API_KEY');
  }

  /// 同期版ホットペッパーAPIキー（テスト用のみ）
  ///
  /// テスト環境でのみ使用可能。本番環境では非同期版を使用してください。
  static String? get hotpepperApiKeySync {
    if (_testHotpepperApiKey != null) {
      return _testHotpepperApiKey;
    }
    
    if (isProduction) {
      throw UnsupportedError('本番環境では非同期版のAPIキー取得を使用してください');
    }
    
    return const String.fromEnvironment('HOTPEPPER_API_KEY');
  }

  /// Google Maps APIキー
  ///
  /// 環境変数 GOOGLE_MAPS_API_KEY から取得
  /// 設定されていない場合はnullを返す
  static String? get googleMapsApiKey {
    return const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  }

  /// APIキーが設定されているかどうかをチェック（同期版）
  ///
  /// テスト環境および開発環境でのみ使用可能
  static bool get hasHotpepperApiKey {
    if (isProduction) {
      // 本番環境では非同期版を使用すべきため、警告を出力
      return false;
    }
    
    final key = hotpepperApiKeySync;
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// APIキーが設定されているかどうかをチェック（非同期版）
  ///
  /// 本番環境では必ずこちらを使用してください
  static Future<bool> get hasHotpepperApiKeyAsync async {
    final key = await hotpepperApiKey;
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// Google Maps APIキーが設定されているかどうかをチェック
  static bool get hasGoogleMapsApiKey {
    final key = googleMapsApiKey;
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// 開発環境かどうかを判定
  static bool get isDevelopment {
    return const bool.fromEnvironment('DEVELOPMENT', defaultValue: true);
  }

  /// 本番環境かどうかを判定
  static bool get isProduction {
    return const bool.fromEnvironment('PRODUCTION', defaultValue: false);
  }

  /// デバッグ情報を表示
  static Map<String, dynamic> get debugInfo {
    return {
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'hasHotpepperApiKey': hasHotpepperApiKey,
      'hasGoogleMapsApiKey': hasGoogleMapsApiKey,
    };
  }

  /// テスト用にAPIキーを設定
  static void setTestApiKey(String apiKey) {
    _testHotpepperApiKey = apiKey;
  }

  /// テスト用APIキーをクリア
  static void clearTestApiKey() {
    _testHotpepperApiKey = null;
    _testGoogleMapsApiKey = null;
  }
}
