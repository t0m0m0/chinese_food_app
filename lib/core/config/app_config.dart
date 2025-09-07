import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/infrastructure/security_exception.dart';
import 'api_config.dart';
import 'ui_config.dart';
import 'database_config.dart';
import 'location_config.dart';
import 'search_config.dart';
import 'validation/config_validator_facade.dart';

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

  // Singleton instances for memory efficiency
  static final ApiConfigAccessor _apiAccessor = ApiConfigAccessor._();
  static final UiConfigAccessor _uiAccessor = UiConfigAccessor._();
  static final DatabaseConfigAccessor _databaseAccessor =
      DatabaseConfigAccessor._();
  static final LocationConfigAccessor _locationAccessor =
      LocationConfigAccessor._();
  static final SearchConfigAccessor _searchAccessor = SearchConfigAccessor._();

  /// API設定への統一アクセス
  static ApiConfigAccessor get api => _apiAccessor;

  /// UI設定への統一アクセス
  static UiConfigAccessor get ui => _uiAccessor;

  /// データベース設定への統一アクセス
  static DatabaseConfigAccessor get database => _databaseAccessor;

  /// ロケーション設定への統一アクセス
  static LocationConfigAccessor get location => _locationAccessor;

  /// 検索設定への統一アクセス
  static SearchConfigAccessor get search => _searchAccessor;

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
    // 新しい統合検証システムを使用
    return ConfigValidatorFacade.validateAll();
  }

  /// ホットペッパーAPIキー
  ///
  /// テスト環境: テスト用APIキーを使用
  /// 本番環境: flutter_secure_storage から取得
  /// 開発環境: 環境変数から取得
  static Future<String?> get hotpepperApiKey async {
    developer.log('🔑 Retrieving HotPepper API key', name: 'AppConfig');

    // テスト環境ではテスト用APIキーを使用
    if (_testHotpepperApiKey != null) {
      developer.log('✅ Using test API key', name: 'AppConfig');
      return _testHotpepperApiKey;
    }

    // 本番環境では secure_storage を使用
    if (isProduction) {
      developer.log('🔐 Accessing secure storage for production API key',
          name: 'AppConfig');
      try {
        final key = await _storage.read(key: 'HOTPEPPER_API_KEY');
        if (key == null || key.isEmpty) {
          developer.log('❌ API key not found in secure storage',
              name: 'AppConfig', level: 1000);
          throw APIKeyNotFoundException(
            'HotPepper API',
            context: 'セキュアストレージにAPIキーが設定されていません',
          );
        }
        developer.log('✅ Production API key retrieved successfully',
            name: 'AppConfig');
        return key;
      } catch (e) {
        // 開発時にはログ出力
        if (isDevelopment) {
          developer.log(
            '❌ HotPepper APIキー取得エラー: ${e.toString()}',
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
    developer.log('🔍 Checking .env file for API key', name: 'AppConfig');
    final envKey = dotenv.env['HOTPEPPER_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      developer.log('✅ API key found in .env file', name: 'AppConfig');
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
  static Future<void> initialize({
    bool force = false,
    bool throwOnValidationError = false,
    bool enableDebugLogging = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    developer.log('🚀 Starting AppConfig initialization', name: 'AppConfig');

    if (_initialized && !force) {
      developer.log('✅ AppConfig already initialized, skipping',
          name: 'AppConfig');
      return;
    }

    try {
      developer.log('📁 Loading .env file', name: 'AppConfig');
      // .envファイルが存在する場合のみ読み込み
      await dotenv.load();
      developer.log('✅ .env file loaded successfully', name: 'AppConfig');
    } catch (e) {
      // .envファイルが存在しない場合や読み込みエラーは無視
      // 本番環境や環境変数が直接設定されている場合は問題なし
      developer.log(
          'ℹ️ .env file not found or failed to load (this is normal in production)',
          name: 'AppConfig');
    }

    // 初期化完了 - ConfigManager依存を削除済み
    stopwatch.stop();
    _initialized = true;

    developer.log(
        '🎉 AppConfig initialization completed in ${stopwatch.elapsedMilliseconds}ms',
        name: 'AppConfig');
  }

  /// テスト用の強制初期化解除
  ///
  /// テスト環境での初期化状態のリセットに使用します
  static void forceUninitialize() {
    _initialized = false;
    _testHotpepperApiKey = null;
    // ConfigManager依存を削除済み
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
    return _isValidApiKey(key);
  }

  /// HotPepper APIキーの形式を検証
  ///
  /// HotPepper APIキーは通常32文字の英数字です
  static bool _isValidApiKey(String? key) {
    if (key == null || key.isEmpty) return false;
    if (key == 'YOUR_API_KEY_HERE') return false;

    // HotPepper APIキーの形式チェック（32文字の英数字）
    final apiKeyPattern = RegExp(r'^[a-zA-Z0-9]{32}$');
    final isValidFormat = apiKeyPattern.hasMatch(key);

    if (!isValidFormat && isDevelopment) {
      // セキュリティ: 開発環境でのみAPI検証の詳細をログ出力
      developer.log('⚠️ API key format validation failed', name: 'AppConfig');
    }

    return isValidFormat;
  }

  /// APIキーの詳細検証（開発・デバッグ用）
  static Map<String, dynamic> validateApiKey(String? key) {
    return {
      'exists': key != null,
      'notEmpty': key != null && key.isNotEmpty,
      'notPlaceholder': key != 'YOUR_API_KEY_HERE',
      'validFormat': _isValidApiKey(key),
      'length': key?.length ?? 0,
      'isProduction': isProduction,
      'keySource': _getApiKeySource(),
    };
  }

  /// APIキー取得元を特定（デバッグ用）
  static String _getApiKeySource() {
    if (_testHotpepperApiKey != null) return 'test';
    if (isProduction) return 'secure_storage';
    return 'environment';
  }

  /// 開発環境かどうかを判定
  static bool get isDevelopment {
    // セキュリティ: 本番環境での設定ミス時にログ漏洩を防ぐため、デフォルトはfalse
    return const bool.fromEnvironment('DEVELOPMENT', defaultValue: false);
  }

  /// 本番環境かどうかを判定
  static bool get isProduction {
    // セキュリティ: 未指定の場合は本番環境として動作（より安全）
    return const bool.fromEnvironment('PRODUCTION', defaultValue: true);
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
    // 本番環境での誤用を防止
    if (isProduction) {
      developer.log('❌ Test API key setup blocked in production environment',
          name: 'AppConfig', level: 1000);
      throw StateError(
          'Test API key setup is not allowed in production environment');
    }

    developer.log('🧪 Setting test API key', name: 'AppConfig');
    _testHotpepperApiKey = apiKey;
  }

  /// テスト用APIキーをすべてクリア
  static void clearTestApiKey() {
    // 本番環境での誤用を防止
    if (isProduction) {
      developer.log('❌ Test API key cleanup blocked in production environment',
          name: 'AppConfig', level: 1000);
      throw StateError(
          'Test API key cleanup is not allowed in production environment');
    }

    developer.log('🧹 Clearing test API key', name: 'AppConfig');
    _testHotpepperApiKey = null;
  }

  /// 初期化状態をリセット（テスト用）
  static void resetInitialization() {
    // 本番環境での誤用を防止
    if (isProduction) {
      developer.log('❌ Initialization reset blocked in production environment',
          name: 'AppConfig', level: 1000);
      throw StateError(
          'Initialization reset is not allowed in production environment');
    }

    developer.log('🔄 Resetting initialization state', name: 'AppConfig');
    _initialized = false;
  }
}

/// API設定へのアクセサークラス
class ApiConfigAccessor {
  ApiConfigAccessor._();

  /// HotPepper API キー
  String get hotpepperApiKey {
    // AppConfigの同期版APIキーを使用
    return AppConfig.hotpepperApiKeySync ?? '';
  }

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

  static const String _distanceKey = 'search_distance_range';

  /// デフォルト検索範囲
  int get defaultSearchRange => SearchConfig.defaultRange;

  /// 最大結果数
  int get maxResults => SearchConfig.maxCount;

  /// 距離設定を保存
  ///
  /// [range] HotPepper API準拠の距離範囲（1=300m, 2=500m, 3=1000m, 4=2000m, 5=3000m）
  Future<void> saveDistance(int range) async {
    developer.log('💾 Saving distance setting: $range', name: 'SearchConfig');

    if (!SearchConfig.isValidRange(range)) {
      developer.log('❌ Invalid range value: $range',
          name: 'SearchConfig', level: 1000);
      throw ArgumentError(
          'Invalid range value: $range. Valid values: 1-5 (SearchConfig.validRanges)');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_distanceKey, range);
      developer.log('✅ Distance setting saved successfully: $range',
          name: 'SearchConfig');
    } catch (e) {
      developer.log('❌ Failed to save distance setting: ${e.toString()}',
          name: 'SearchConfig', level: 1000);
      throw Exception('Failed to save distance setting: $e');
    }
  }

  /// 距離設定を取得（デフォルトは1000m）
  ///
  /// 戻り値: HotPepper API準拠の距離範囲（1-5）
  Future<int> getDistance() async {
    developer.log('📖 Getting distance setting', name: 'SearchConfig');

    try {
      final prefs = await SharedPreferences.getInstance();
      final distance = prefs.getInt(_distanceKey) ?? SearchConfig.defaultRange;
      developer.log('✅ Distance setting retrieved: $distance',
          name: 'SearchConfig');
      return distance;
    } catch (e) {
      developer.log(
          '❌ Failed to get distance setting, using default: ${SearchConfig.defaultRange}',
          name: 'SearchConfig',
          level: 1000);
      return SearchConfig.defaultRange;
    }
  }

  /// 距離設定をメートル単位で取得
  ///
  /// 戻り値: 距離（メートル）
  Future<int> getDistanceInMeters() async {
    final range = await getDistance();
    return SearchConfig.rangeToMeter(range) ?? 1000;
  }

  /// デバッグ情報
  Map<String, dynamic> get debugInfo => SearchConfig.debugInfo;
}
