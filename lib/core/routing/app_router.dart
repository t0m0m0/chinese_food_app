import 'package:go_router/go_router.dart';
import '../../presentation/pages/swipe/swipe_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/my_menu/my_menu_page.dart';
import '../../presentation/pages/store_detail/store_detail_page.dart';
import '../../presentation/pages/shell/shell_page.dart';
import '../../domain/entities/store.dart';

/// アプリケーションのルーティング設定を管理するクラス
class AppRouter {
  /// GoRouterの設定を生成
  static GoRouter get router => GoRouter(
        initialLocation: '/swipe',
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              return ShellPage(child: child);
            },
            routes: [
              GoRoute(
                path: '/swipe',
                name: 'swipe',
                builder: (context, state) => const SwipePage(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchPage(),
              ),
              GoRoute(
                path: '/my-menu',
                name: 'my-menu',
                builder: (context, state) => const MyMenuPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/store-detail',
            name: 'store-detail',
            builder: (context, state) {
              final Store store = state.extra as Store;
              return StoreDetailPage(store: store);
            },
          ),
        ],
      );
}
