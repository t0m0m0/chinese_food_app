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

/// テスト環境かどうかを判定
bool _isTestEnvironment() {
  // テスト環境では FLUTTER_TEST 環境変数が設定される
  return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
}

Future<void> main() async {
  // アプリ起動時の非同期処理のためFlutterバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

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
