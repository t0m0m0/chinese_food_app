import 'package:go_router/go_router.dart';
import '../../presentation/pages/swipe/swipe_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/my_menu/my_menu_page.dart';
import '../../presentation/pages/store_detail/store_detail_page.dart';
import '../../presentation/pages/visit_record/visit_record_form_page.dart';
import '../../presentation/pages/shell/shell_page.dart';
import '../../presentation/pages/error/error_page.dart';
import '../../domain/entities/store.dart';

/// アプリケーションのルーティング設定を管理するクラス
class AppRouter {
  /// GoRouterの静的インスタンス（パフォーマンス最適化）
  static final GoRouter _router = GoRouter(
    initialLocation: '/swipe',
    errorBuilder: (context, state) => ErrorPage(
      message: 'ページが見つかりません: ${state.uri.path}',
      onRetry: () => context.go('/swipe'),
    ),
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
          // 型安全なキャスト処理
          final Store? store = state.extra as Store?;
          if (store == null) {
            return const ErrorPage(
              message: '店舗情報が見つかりません',
            );
          }
          return StoreDetailPage(store: store);
        },
      ),
      GoRoute(
        path: '/visit-record-form',
        name: 'visit-record-form',
        builder: (context, state) {
          // 型安全なキャスト処理
          final Store? store = state.extra as Store?;
          if (store == null) {
            return const ErrorPage(
              message: '店舗情報が見つかりません',
            );
          }
          return VisitRecordFormPage(store: store);
        },
      ),
    ],
  );

  /// GoRouterの設定を取得
  static GoRouter get router => _router;
}
