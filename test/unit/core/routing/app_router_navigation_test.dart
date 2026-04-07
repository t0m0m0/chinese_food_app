import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/core/routing/app_router.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/pages/error/error_page.dart';
import 'package:chinese_food_app/presentation/pages/visit_record/visit_record_form_page.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import '../di/di_test_helpers.dart';

/// 画面遷移（GoRouter）追加テスト
///
/// パラメータ受け渡し・ディープリンク・エッジケースを検証
void main() {
  late GoRouter router;
  late DIContainerInterface container;

  setUp(() {
    router = AppRouter.router;
    container = DITestHelpers.createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  Widget createApp() {
    return MultiProvider(
      providers: [
        Provider<DIContainerInterface>.value(value: container),
        ChangeNotifierProvider.value(value: container.getStoreProvider()),
        Provider<LocationService>.value(value: container.getLocationService()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('visit-record-form ルート', () {
    testWidgets('正常なStoreが渡された場合、VisitRecordFormPageが表示される', (tester) async {
      final store = Store(
        id: 'vr-test-id',
        name: '訪問記録テスト店舗',
        address: '東京都千代田区テスト1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.visited,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(createApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      router.go('/visit-record-form', extra: store);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VisitRecordFormPage), findsOneWidget);
    });

    testWidgets('Storeが渡されない場合、ErrorPageが表示される', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          FlutterError.presentError(details);
        }
      };

      try {
        await tester.pumpWidget(createApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        router.go('/visit-record-form');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ErrorPage), findsOneWidget);
        expect(find.text('店舗情報が見つかりません'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('nullが渡された場合、ErrorPageが表示される', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          FlutterError.presentError(details);
        }
      };

      try {
        await tester.pumpWidget(createApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        router.go('/visit-record-form', extra: null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ErrorPage), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('タブ間の遷移', () {
    testWidgets('swipe→search→my-menuの連続遷移が正しく動作する', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          FlutterError.presentError(details);
        }
      };

      try {
        await tester.pumpWidget(createApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // /swipe → /search
        router.go('/search');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // /search → /my-menu
        router.go('/my-menu');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // /my-menu → /swipe
        router.go('/swipe');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 最終的に/swipeにいることを確認
        final currentRoute =
            router.routeInformationProvider.value.uri.toString();
        expect(currentRoute, contains('/swipe'));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('エラーハンドリング', () {
    testWidgets('複数の不正ルートにアクセスしてもクラッシュしない', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('RenderFlex overflowed')) {
          FlutterError.presentError(details);
        }
      };

      try {
        await tester.pumpWidget(createApp());
        await tester.pump();

        // 不正なルート
        router.go('/invalid-route');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ErrorPage), findsOneWidget);

        // 正常なルートに戻る
        router.go('/swipe');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final currentRoute =
            router.routeInformationProvider.value.uri.toString();
        expect(currentRoute, contains('/swipe'));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
