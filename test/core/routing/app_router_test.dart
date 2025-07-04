import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:chinese_food_app/core/routing/app_router.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/error/error_page.dart';
import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';
import 'package:chinese_food_app/presentation/pages/search/search_page.dart';
import 'package:chinese_food_app/presentation/pages/my_menu/my_menu_page.dart';
import 'package:chinese_food_app/presentation/pages/store_detail/store_detail_page.dart';

void main() {
  group('AppRouter', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter.router;
    });

    testWidgets('初期ルートは /swipe である', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.byType(SwipePage), findsOneWidget);
    });

    testWidgets('存在しないルートにアクセスした場合、ErrorPageが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // 存在しないルートに遷移
      router.go('/nonexistent');
      await tester.pumpAndSettle();

      expect(find.byType(ErrorPage), findsOneWidget);
      expect(find.text('ページが見つかりません: /nonexistent'), findsOneWidget);
    });

    group('基本ルート遷移', () {
      testWidgets('/swipe ルートでSwipePageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/swipe');
        await tester.pumpAndSettle();

        expect(find.byType(SwipePage), findsOneWidget);
      });

      testWidgets('/search ルートでSearchPageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/search');
        await tester.pumpAndSettle();

        expect(find.byType(SearchPage), findsOneWidget);
      });

      testWidgets('/my-menu ルートでMyMenuPageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/my-menu');
        await tester.pumpAndSettle();

        expect(find.byType(MyMenuPage), findsOneWidget);
      });
    });

    group('店舗詳細ルート', () {
      testWidgets('正常なStoreオブジェクトが渡された場合、StoreDetailPageが表示される',
          (tester) async {
        final store = Store(
          id: 'test-id',
          name: 'テスト店舗',
          address: 'テスト住所',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          createdAt: DateTime(2024, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/store-detail', extra: store);
        await tester.pumpAndSettle();

        expect(find.byType(StoreDetailPage), findsOneWidget);
      });

      testWidgets('Storeオブジェクトが渡されない場合、ErrorPageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/store-detail');
        await tester.pumpAndSettle();

        expect(find.byType(ErrorPage), findsOneWidget);
        expect(find.text('店舗情報が見つかりません'), findsOneWidget);
      });

      testWidgets('nullが渡された場合、ErrorPageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/store-detail', extra: null);
        await tester.pumpAndSettle();

        expect(find.byType(ErrorPage), findsOneWidget);
        expect(find.text('店舗情報が見つかりません'), findsOneWidget);
      });

      testWidgets('間違った型のオブジェクトが渡された場合、ErrorPageが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        router.go('/store-detail', extra: 'wrong-type');
        await tester.pumpAndSettle();

        expect(find.byType(ErrorPage), findsOneWidget);
        expect(find.text('店舗情報が見つかりません'), findsOneWidget);
      });
    });

    group('静的インスタンス最適化', () {
      test('同じGoRouterインスタンスが返される', () {
        final router1 = AppRouter.router;
        final router2 = AppRouter.router;

        expect(identical(router1, router2), isTrue);
      });
    });
  });
}
