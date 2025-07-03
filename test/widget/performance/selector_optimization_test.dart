import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../helpers/test_helper.dart';

/// ConsumerとSelectorの再描画比較テスト
///
/// 目的: Consumer → Selector移行で不要な再描画を防止できることを検証

class ConsumerTestWidget extends StatefulWidget {
  const ConsumerTestWidget({super.key});

  @override
  State<ConsumerTestWidget> createState() => _ConsumerTestWidgetState();
}

class _ConsumerTestWidgetState extends State<ConsumerTestWidget> {
  int storeListBuildCount = 0;
  int loadingIndicatorBuildCount = 0;
  int errorDisplayBuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔴 Consumer使用: 全ての変更で再描画される
          Consumer<StoreProvider>(
            builder: (context, provider, child) {
              storeListBuildCount++;
              return Text('Stores: ${provider.stores.length}');
            },
          ),

          Consumer<StoreProvider>(
            builder: (context, provider, child) {
              loadingIndicatorBuildCount++;
              return provider.isLoading
                  ? const CircularProgressIndicator()
                  : const SizedBox();
            },
          ),

          Consumer<StoreProvider>(
            builder: (context, provider, child) {
              errorDisplayBuildCount++;
              return provider.error != null
                  ? Text('Error: ${provider.error}')
                  : const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

class SelectorTestWidget extends StatefulWidget {
  const SelectorTestWidget({super.key});

  @override
  State<SelectorTestWidget> createState() => _SelectorTestWidgetState();
}

class _SelectorTestWidgetState extends State<SelectorTestWidget> {
  int storeListBuildCount = 0;
  int loadingIndicatorBuildCount = 0;
  int errorDisplayBuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🟢 Selector使用: 特定の状態変更のみで再描画
          Selector<StoreProvider, List<Store>>(
            selector: (context, provider) => provider.stores,
            builder: (context, stores, child) {
              storeListBuildCount++;
              return Text('Stores: ${stores.length}');
            },
          ),

          Selector<StoreProvider, bool>(
            selector: (context, provider) => provider.isLoading,
            builder: (context, isLoading, child) {
              loadingIndicatorBuildCount++;
              return isLoading
                  ? const CircularProgressIndicator()
                  : const SizedBox();
            },
          ),

          Selector<StoreProvider, String?>(
            selector: (context, provider) => provider.error,
            builder: (context, error, child) {
              errorDisplayBuildCount++;
              return error != null ? Text('Error: $error') : const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Selector最適化テスト', () {
    late StoreProvider storeProvider;

    setUp(() {
      storeProvider = TestsHelper.createStoreProvider();
    });

    testWidgets('🔴 Red: ConsumerはerrorのクリアでもStoreListが再描画される', (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const ConsumerTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期描画カウントを取得
      final initialStoreListBuildCount =
          (tester.state(find.byType(ConsumerTestWidget))
                  as _ConsumerTestWidgetState)
              .storeListBuildCount;

      // errorをクリア（これでnotifyListeners()が呼ばれる）
      storeProvider.clearError();
      await tester.pump();

      final afterErrorClearStoreListBuildCount =
          (tester.state(find.byType(ConsumerTestWidget))
                  as _ConsumerTestWidgetState)
              .storeListBuildCount;

      // 🔴 Consumerは全ての変更で再描画される
      expect(afterErrorClearStoreListBuildCount,
          greaterThan(initialStoreListBuildCount),
          reason: 'ConsumerはerrorCleanでもStoreListが再描画される（最適化されていない）');
    });

    testWidgets('🟢 Green: Selectorはerror変更時にStoreListは再描画されない',
        (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const SelectorTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期描画カウントを取得
      final initialStoreListBuildCount =
          (tester.state(find.byType(SelectorTestWidget))
                  as _SelectorTestWidgetState)
              .storeListBuildCount;

      // errorをクリア
      storeProvider.clearError();
      await tester.pump();

      final afterErrorClearStoreListBuildCount =
          (tester.state(find.byType(SelectorTestWidget))
                  as _SelectorTestWidgetState)
              .storeListBuildCount;

      // 🟢 Selectorは対象の状態変更のみで再描画される
      expect(afterErrorClearStoreListBuildCount,
          equals(initialStoreListBuildCount),
          reason: 'SelectorはerrorCleanではStoreListは再描画されない（最適化されている）');
    });

    testWidgets('🟢 Green: stores変更時はSelectorでもStoreListが再描画される',
        (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const SelectorTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期描画カウントを取得
      final initialStoreListBuildCount =
          (tester.state(find.byType(SelectorTestWidget))
                  as _SelectorTestWidgetState)
              .storeListBuildCount;

      // 新しい店舗を追加（storesが変更される）
      final newStore = TestsHelper.createTestStore(
        id: 'new-store-1',
        name: 'New Test Store',
      );
      await storeProvider.addStore(newStore);
      await tester.pump();

      final afterStoreAddStoreListBuildCount =
          (tester.state(find.byType(SelectorTestWidget))
                  as _SelectorTestWidgetState)
              .storeListBuildCount;

      // storeListは正しく再描画される
      expect(afterStoreAddStoreListBuildCount,
          greaterThan(initialStoreListBuildCount),
          reason: 'SelectorでもStoreList対象のstores変更時は正しく再描画される');
    });
  });
}
