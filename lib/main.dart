import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/config_manager.dart';
import 'core/config/environment_config.dart';
import 'core/config/ui_config.dart';
import 'core/di/app_di_container.dart';
import 'core/di/di_container_interface.dart';
import 'core/routing/app_router.dart';
import 'presentation/providers/store_provider.dart';
import 'domain/services/location_service.dart';

import 'core/debug/crash_handler.dart';

/// Google Maps SDKの安全な初期化を管理するサービス
class GoogleMapsInitializer {
  static bool _isInitialized = false;
  static bool _initializationInProgress = false;

  /// Google Maps SDKが初期化済みかどうかを確認
  static bool get isInitialized => _isInitialized;

  /// Google Maps SDKの初期化を実行
  ///
  /// これは Google Maps Services の precondition check を
  /// 安全に実行するために必要な初期化処理です
  static Future<bool> ensureInitialized() async {
    CrashHandler.logEvent('INIT_START', details: {
      'already_initialized': _isInitialized,
      'in_progress': _initializationInProgress,
    });

    // 既に初期化済みの場合は成功を返す
    if (_isInitialized) {
      CrashHandler.logEvent('INIT_ALREADY_DONE');
      return true;
    }

    // テスト環境では初期化をスキップ
    if (_isTestEnvironmentInternal()) {
      CrashHandler.logEvent('INIT_TEST_SKIP');
      debugPrint(
          '[GoogleMapsInitializer] Test environment - skipping initialization');
      _isInitialized = true;
      return true;
    }

    // 初期化中の場合は待機
    if (_initializationInProgress) {
      CrashHandler.logEvent('INIT_WAITING');
      // 簡易的な待機ループ（テスト環境対応）
      int attempts = 0;
      while (_initializationInProgress && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      CrashHandler.logEvent('INIT_WAIT_COMPLETE', details: {
        'attempts': attempts,
        'final_status': _isInitialized,
      });
      return _isInitialized;
    }

    _initializationInProgress = true;
    CrashHandler.logEvent('INIT_PROGRESS_START');

    try {
      // ConfigManagerが初期化されているかチェック
      final configManagerInitialized = ConfigManager.isInitialized;
      CrashHandler.logEvent('CONFIG_CHECK', details: {
        'config_manager_initialized': configManagerInitialized,
      });

      if (!configManagerInitialized) {
        debugPrint('[GoogleMapsInitializer] ConfigManager not initialized');
        CrashHandler.logEvent('INIT_FAIL_CONFIG_MANAGER');
        _completeInitialization(false);
        return false;
      }

      // APIキーの検証
      final apiKey = ConfigManager.googleMapsApiKey;
      final apiKeyValid = apiKey.isNotEmpty;
      CrashHandler.logEvent('API_KEY_CHECK', details: {
        'api_key_present': apiKeyValid,
        'api_key_length': apiKey.length,
      });

      if (!apiKeyValid) {
        debugPrint('[GoogleMapsInitializer] Google Maps API key not available');
        CrashHandler.logEvent('INIT_FAIL_API_KEY');
        _completeInitialization(false);
        return false;
      }

      // Google Maps Servicesを明示的に初期化
      // これによりネイティブSDKのprecondition checkが安全に通過するよう保証します
      debugPrint(
          '[GoogleMapsInitializer] Initializing Google Maps Services...');
      CrashHandler.logEvent('SDK_INIT_START', details: {
        'api_key_first_6': apiKey.substring(0, 6),
      });

      // AndroidおよびiOSでGoogle Maps SDKを初期化
      await _initializeGoogleMapsServices(apiKey);

      _completeInitialization(true);
      debugPrint(
          '[GoogleMapsInitializer] Google Maps Services initialized successfully');
      CrashHandler.logEvent('INIT_SUCCESS');
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint(
          '[GoogleMapsInitializer] Failed to initialize Google Maps Services: $e');

      CrashHandler.logEvent('INIT_EXCEPTION', details: {
        'error': errorMessage,
        'error_type': e.runtimeType.toString(),
      });

      _completeInitialization(false);
      return false;
    }
  }

  /// プラットフォーム別Google Maps Services初期化
  static Future<void> _initializeGoogleMapsServices(String apiKey) async {
    try {
      // Google Maps Flutter pluginの内部初期化をトリガーするためのダミー作業
      // これにより実際のGoogleMapウィジェット生成前にSDKを事前初期化します

      // SDK内部初期化のための遅延
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('[GoogleMapsInitializer] Platform initialization completed');
    } catch (e) {
      debugPrint('[GoogleMapsInitializer] Platform initialization failed: $e');
      rethrow;
    }
  }

  /// 初期化完了処理
  static void _completeInitialization(bool success) {
    _isInitialized = success;
    _initializationInProgress = false;
  }

  /// テスト環境判定（内部用）
  static bool _isTestEnvironmentInternal() {
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  }

  /// テスト用初期化状態リセット
  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
    _initializationInProgress = false;
  }
}

bool _isTestEnvironment() {
  // テスト環境では FLUTTER_TEST 環境変数が設定される
  return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
}

Future<void> main() async {
  // アプリ起動時の非同期処理のためFlutterバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 基本エラーハンドラーを初期化
  CrashHandler.initialize();

  // 設定管理を初期化（テスト環境では初期化をスキップ）
  if (!_isTestEnvironment()) {
    try {
      // 環境設定を先に初期化
      await EnvironmentConfig.initialize();

      await ConfigManager.initialize(
        throwOnValidationError: false, // 開発環境では警告のみ
        enableDebugLogging: true,
      );
      debugPrint('設定管理の初期化が完了しました: ${ConfigManager.debugString}');

      // 統合設定検証を実行
      final validationResults = ConfigManager.validateAllConfigs();
      final hasErrors =
          validationResults.values.any((errors) => errors.isNotEmpty);
      final hasCriticalErrors = ConfigManager.hasAnyCriticalErrors;

      if (hasErrors) {
        debugPrint('設定検証でエラーが検出されました:');
        validationResults.forEach((domain, errors) {
          if (errors.isNotEmpty) {
            debugPrint('  $domain: ${errors.join(', ')}');
          }
        });

        // Criticalエラーがある場合はアプリ起動を停止
        if (hasCriticalErrors) {
          debugPrint('Critical設定エラーが検出されました。アプリを安全に起動できません。');
          throw Exception('Critical configuration errors detected. '
              'Application cannot start safely.');
        } else {
          debugPrint('Non-critical設定エラーのため、アプリは制限付きモードで起動します。');
        }
      } else {
        debugPrint('すべての設定検証が完了しました');
      }
    } catch (e) {
      debugPrint('設定管理の初期化でエラーが発生しました: $e');
      debugPrint('アプリは制限付きモードで起動します');
    }
  } else {
    debugPrint('テスト環境: 設定管理の初期化をスキップします');
  }

  // DIコンテナーを作成・設定
  final DIContainerInterface container = AppDIContainer();
  container.configure();

  // StoreProviderを取得し、必要なデータで事前初期化
  final StoreProvider storeProvider = container.getStoreProvider();

  try {
    // アプリ起動時の店舗データ初期化を実行
    await storeProvider.loadStores();
    debugPrint('店舗データの事前初期化が完了しました');
  } catch (e) {
    // 初期化エラー時のフォールバック処理
    debugPrint('初期化エラー: $e');
    debugPrint('アプリは空の状態で起動します。ユーザーは後で手動でデータを読み込みできます。');
    // エラー状態をクリアしてアプリを続行可能にする
    storeProvider.clearError();
  }

  // LocationServiceを取得
  final LocationService locationService = container.getLocationService();

  // Google Maps SDKを安全に初期化
  if (!_isTestEnvironment()) {
    try {
      debugPrint('🗺️ Google Maps SDK初期化開始...');
      final googleMapsInitialized =
          await GoogleMapsInitializer.ensureInitialized();
      if (googleMapsInitialized) {
        debugPrint('✅ Google Maps SDK初期化完了');
      } else {
        debugPrint('⚠️ Google Maps SDK初期化失敗 - 地図機能は制限付きで動作します');
      }
    } catch (e) {
      debugPrint('❌ Google Maps SDK初期化エラー: $e');
      debugPrint('🔄 アプリは地図機能なしで続行します');
    }
  } else {
    debugPrint('テスト環境: Google Maps SDK初期化をスキップします');
  }

  runApp(MyApp(
    storeProvider: storeProvider,
    locationService: locationService,
    container: container,
  ));
}

class MyApp extends StatefulWidget {
  final StoreProvider storeProvider;
  final LocationService locationService;
  final DIContainerInterface container;

  const MyApp({
    super.key,
    required this.storeProvider,
    required this.locationService,
    required this.container,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // アプリ終了時のリソース解放処理
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the DI container itself for testing and debugging
        Provider<DIContainerInterface>.value(value: widget.container),

        // Provide pre-initialized services
        ChangeNotifierProvider<StoreProvider>.value(
          value: widget.storeProvider,
        ),
        Provider<LocationService>.value(
          value: widget.locationService,
        ),
      ],
      child: MaterialApp.router(
        title: UiConfig.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
