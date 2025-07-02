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
  // Ensure Flutter binding is initialized for async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Create and configure DI container
  final DIContainerInterface container = AppDIContainer();
  container.configure();

  // Pre-initialize StoreProvider with essential data
  final storeProvider = container.getStoreProvider();
  await storeProvider.loadStores();

  // Get LocationService
  final locationService = container.getLocationService();

  runApp(MyApp(
    storeProvider: storeProvider,
    locationService: locationService,
    container: container,
  ));
}

class MyApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the DI container itself for testing and debugging
        Provider<DIContainerInterface>.value(value: container),

        // Provide pre-initialized services
        ChangeNotifierProvider<StoreProvider>.value(
          value: storeProvider,
        ),
        Provider<LocationService>.value(
          value: locationService,
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
