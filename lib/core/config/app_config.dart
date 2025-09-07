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
  static Future<void> initialize({
    bool force = false,
    bool throwOnValidationError = false,
    bool enableDebugLogging = false,
  }) async {
    if (_initialized && !force) return;

    try {
      // .envファイルが存在する場合のみ読み込み
      await dotenv.load();
    } catch (e) {
      // .envファイルが存在しない場合や読み込みエラーは無視
      // 本番環境や環境変数が直接設定されている場合は問題なし
    }

    // 初期化完了 - ConfigManager依存を削除済み

    _initialized = true;
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
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// 開発環境かどうかを判定
  static bool get isDevelopment {
    // 環境変数ベース
    return const bool.fromEnvironment('DEVELOPMENT', defaultValue: true);
  }

  /// 本番環境かどうかを判定
  static bool get isProduction {
    // 環境変数ベース
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
    if (!SearchConfig.isValidRange(range)) {
      throw ArgumentError('Invalid range value: $range');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_distanceKey, range);
  }

  /// 距離設定を取得（デフォルトは1000m）
  ///
  /// 戻り値: HotPepper API準拠の距離範囲（1-5）
  Future<int> getDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_distanceKey) ?? SearchConfig.defaultRange;
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
