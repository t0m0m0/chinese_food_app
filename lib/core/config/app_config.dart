import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/infrastructure/security_exception.dart';
import 'api_config.dart';
import 'ui_config.dart';
import 'database_config.dart';
import 'location_config.dart';
import 'search_config.dart';

/// アプリケーション設定管理クラス
///
/// 環境変数やAPIキーなどの機密情報を安全に管理します。
/// 本番環境では flutter_secure_storage を使用して機密情報を保護します。
///
/// Facade Pattern を使用してすべての設定への統一アクセスを提供します。
class AppConfig {
  // テスト用のAPIキー保存
  static String? _testHotpepperApiKey;

  // 初期化フラグ
  static bool _initialized = false;

  // セキュアストレージのインスタンス
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// アプリの初期化状態を取得
  static bool get isInitialized => _initialized;

  /// API設定への統一アクセス
  static ApiConfigAccessor get api => ApiConfigAccessor._();

  /// UI設定への統一アクセス
  static UiConfigAccessor get ui => UiConfigAccessor._();

  /// データベース設定への統一アクセス
  static DatabaseConfigAccessor get database => DatabaseConfigAccessor._();

  /// ロケーション設定への統一アクセス
  static LocationConfigAccessor get location => LocationConfigAccessor._();

  /// 検索設定への統一アクセス
  static SearchConfigAccessor get search => SearchConfigAccessor._();

  /// 設定システムが有効かどうか
  static bool get isValid {
    final errors = validationErrors;
    return errors.isEmpty;
  }

  /// 設定検証エラーのリスト
  static List<String> get validationErrors {
    final results = validateAll();
    final List<String> allErrors = [];
    for (final errors in results.values) {
      allErrors.addAll(errors);
    }
    return allErrors;
  }

  /// すべての設定を検証
  static Map<String, List<String>> validateAll() {
    return {
      'api': [], // TODO: API設定の検証を実装
      'ui': [], // TODO: UI設定の検証を実装
      'database': [], // TODO: データベース設定の検証を実装
      'location': [], // TODO: ロケーション設定の検証を実装
      'search': [], // TODO: 検索設定の検証を実装
    };
  }

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
        final key = await _storage.read(key: 'HOTPEPPER_API_KEY');
        if (key == null || key.isEmpty) {
          throw APIKeyNotFoundException(
            'HotPepper API',
            context: 'セキュアストレージにAPIキーが設定されていません',
          );
        }
        return key;
      } catch (e) {
        // 開発時にはログ出力
        if (isDevelopment) {
          developer.log(
            'HotPepper APIキー取得エラー: ${e.toString()}',
            name: 'AppConfig',
            level: 1000,
          );
        }

        if (e is SecurityException) {
          rethrow;
        }

        throw APIKeyAccessException(
          'HotPepper API',
          'セキュアストレージからの読み込みに失敗しました',
          context: '本番環境でのAPIキー取得',
          originalException: e is Exception ? e : Exception(e.toString()),
        );
      }
    }

    // 開発環境では.envファイルまたは環境変数から取得
    await initialize();

    // .envファイルから取得を試行
    final envKey = dotenv.env['HOTPEPPER_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // 環境変数から取得（フォールバック）
    final environmentKey = const String.fromEnvironment('HOTPEPPER_API_KEY');

    // 開発者への設定ガイダンス
    if (isDevelopment && environmentKey.isEmpty) {
      developer.log(
        '推奨: .envファイルにHOTPEPPER_API_KEY=your_key_here を設定してください',
        name: 'AppConfig',
      );
    }

    return environmentKey;
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

    // .envファイルから取得を試行（既に初期化済みの場合のみ）
    if (_initialized) {
      final envKey = dotenv.env['HOTPEPPER_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    }

    return const String.fromEnvironment('HOTPEPPER_API_KEY');
  }

  /// アプリ初期化（後方互換性のため）
  ///
  /// .envファイルの読み込みを行います（存在する場合のみ）
  static Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    try {
      // .envファイルが存在する場合のみ読み込み
      await dotenv.load();
    } catch (e) {
      // .envファイルが存在しない場合や読み込みエラーは無視
      // 本番環境や環境変数が直接設定されている場合は問題なし
    }

    _initialized = true;
  }

  /// Google Maps APIキー（WebView実装により使用していません）
  ///
  /// WebView地図実装により、Google Maps APIキーは不要になりました。
  /// 互換性のため残していますが、常に空文字列を返します。
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static Future<String?> get googleMapsApiKey async {
    // WebView実装により不要だが、互換性のため空文字列を返す
    return '';
  }

  /// Google Maps APIキー（同期版・WebView実装により使用していません）
  ///
  /// WebView地図実装により不要になりました。互換性のため残しています。
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static String? get googleMapsApiKeySync {
    // WebView実装により不要だが、互換性のため空文字列を返す
    return '';
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

  /// Google Maps APIキーが設定されているかどうかをチェック（WebView実装により不要）
  ///
  /// WebView地図実装により、Google Maps APIキーは不要になりました。
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static bool get hasGoogleMapsApiKey {
    // WebView実装により常にfalseを返す
    return false;
  }

  /// Google Maps APIキーが設定されているかどうかをチェック（WebView実装により不要）
  ///
  /// WebView地図実装により、Google Maps APIキーは不要になりました。
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static Future<bool> get hasGoogleMapsApiKeyAsync async {
    // WebView実装により常にfalseを返す
    return false;
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
      'initialized': _initialized,
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'hasHotpepperApiKey': hasHotpepperApiKey,
      'hasGoogleMapsApiKey': false, // WebView実装により不要
      'api': api.debugInfo,
      'ui': ui.debugInfo,
      'database': database.debugInfo,
      'location': location.debugInfo,
      'search': search.debugInfo,
    };
  }

  /// テスト用にHotPepper APIキーを設定
  static void setTestApiKey(String apiKey) {
    _testHotpepperApiKey = apiKey;
  }

  /// テスト用にGoogle Maps APIキーを設定（WebView実装により不要）
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static void setTestGoogleMapsApiKey(String apiKey) {
    // WebView実装により何もしない（互換性のため残す）
  }

  /// テスト用APIキーをすべてクリア
  static void clearTestApiKey() {
    _testHotpepperApiKey = null;
  }

  /// 初期化状態をリセット（テスト用）
  static void resetInitialization() {
    _initialized = false;
  }
}

/// API設定へのアクセサークラス
class ApiConfigAccessor {
  ApiConfigAccessor._();

  /// HotPepper API キー
  String get hotpepperApiKey => AppConfig.hotpepperApiKeySync ?? '';

  /// HotPepper API URL
  String get hotpepperApiUrl => ApiConfig.hotpepperApiUrl;

  /// HotPepper API タイムアウト
  int get hotpepperApiTimeout => ApiConfig.hotpepperApiTimeout;

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => ApiConfig.debugInfo;
}

/// UI設定へのアクセサークラス
class UiConfigAccessor {
  UiConfigAccessor._();

  /// アプリ名
  String get appName => UiConfig.appName;

  /// デフォルトパディング
  double get defaultPadding => UiConfig.defaultPadding;

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => UiConfig.debugInfo;
}

/// データベース設定へのアクセサークラス
class DatabaseConfigAccessor {
  DatabaseConfigAccessor._();

  /// データベース名
  String get databaseName => DatabaseConfig.databaseName;

  /// データベースバージョン
  int get databaseVersion => DatabaseConfig.databaseVersion;

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => DatabaseConfig.debugInfo;
}

/// ロケーション設定へのアクセサークラス
class LocationConfigAccessor {
  LocationConfigAccessor._();

  /// ロケーション精度
  dynamic get locationAccuracy => LocationConfig.defaultAccuracy;

  /// ロケーションタイムアウト
  int get locationTimeout => LocationConfig.defaultTimeoutSeconds;

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => LocationConfig.debugInfo;
}

/// 検索設定へのアクセサークラス
class SearchConfigAccessor {
  SearchConfigAccessor._();

  /// デフォルト検索範囲
  int get defaultSearchRange => SearchConfig.defaultRange;

  /// 最大結果数
  int get maxResults => SearchConfig.maxCount;

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => SearchConfig.debugInfo;
}
