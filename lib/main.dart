import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_di_container.dart';
import 'core/di/di_container_interface.dart';
import 'presentation/pages/my_menu/my_menu_page.dart';
import 'presentation/pages/search/search_page.dart';
import 'presentation/pages/swipe/swipe_page.dart';
import 'presentation/providers/store_provider.dart';
import 'domain/services/location_service.dart';

Future<void> main() async {
  // アプリ起動時の非同期処理のためFlutterバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

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
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SwipePage(),
    const SearchPage(),
    const MyMenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swipe),
            label: 'スワイプ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'マイメニュー',
          ),
        ],
      ),
    );
  }
}
