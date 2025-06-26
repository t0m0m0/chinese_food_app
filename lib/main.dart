import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'core/constants/app_constants.dart';
import 'core/config/app_config.dart';
import 'core/database/database_helper.dart';
import 'data/datasources/hotpepper_api_datasource.dart';
import 'data/datasources/store_local_datasource.dart';
import 'data/repositories/store_repository_impl.dart';
import 'presentation/pages/my_menu/my_menu_page.dart';
import 'presentation/pages/search/search_page.dart';
import 'presentation/pages/swipe/swipe_page.dart';
import 'presentation/providers/store_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => _createStoreProvider(),
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

  /// StoreProviderの依存関係を注入して作成
  StoreProvider _createStoreProvider() {
    // 本番環境ではAPIキーが設定されている場合のみ実API使用
    final HotpepperApiDatasource apiDatasource;
    if (AppConfig.hasHotpepperApiKey && AppConfig.isProduction) {
      apiDatasource = HotpepperApiDatasourceImpl(
        client: http.Client(),
      );
    } else {
      // 開発環境またはAPIキー未設定時はモック使用
      apiDatasource = MockHotpepperApiDatasource();
    }

    final localDatasource =
        StoreLocalDatasourceImpl(dbHelper: DatabaseHelper());
    final repository = StoreRepositoryImpl(
      apiDatasource: apiDatasource,
      localDatasource: localDatasource,
    );

    return StoreProvider(repository: repository);
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
