import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../helpers/test_helpers.dart';

/// Selectorを使った最適化の動作確認テスト
///
/// 目的: Consumer → Selector移行で正しく動作することを検証

class SelectorTestWidget extends StatefulWidget {
  const SelectorTestWidget({super.key});

  @override
  State<SelectorTestWidget> createState() => _SelectorTestWidgetState();
}

class _SelectorTestWidgetState extends State<SelectorTestWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Selector使用: 特定の状態変更のみで再描画
          Selector<StoreProvider, List<Store>>(
            selector: (context, provider) => provider.stores,
            builder: (context, stores, child) {
              return Text('Stores: ${stores.length}');
            },
          ),

          Selector<StoreProvider, bool>(
            selector: (context, provider) => provider.isLoading,
            builder: (context, isLoading, child) {
              return isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Not Loading');
            },
          ),

          Selector<StoreProvider, String?>(
            selector: (context, provider) => provider.error,
            builder: (context, error, child) {
              return error != null
                  ? Text('Error: $error')
                  : const Text('No Error');
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

    testWidgets('Selectorの基本動作を確認', (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const SelectorTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期状態のテキストを確認
      expect(find.text('Stores: 0'), findsOneWidget);
      expect(find.text('Not Loading'), findsOneWidget);
      expect(find.text('No Error'), findsOneWidget);
    });

    testWidgets('stores変更時はSelectorが正しく再描画される', (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const SelectorTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期状態のテキストを確認
      expect(find.text('Stores: 0'), findsOneWidget);

      // 新しい店舗を追加（storesが変更される）
      final newStore = TestsHelper.createTestStore(
        id: 'new-store-1',
        name: 'New Test Store',
      );
      await storeProvider.addStore(newStore);
      await tester.pump();

      // 店舗数が更新されていることを確認
      expect(find.text('Stores: 1'), findsOneWidget);
    });

    testWidgets('複数の店舗追加でもSelectorが正しく動作する', (tester) async {
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: const SelectorTestWidget(),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 複数の店舗を追加
      for (int i = 1; i <= 3; i++) {
        final store = TestsHelper.createTestStore(
          id: 'store-$i',
          name: 'Test Store $i',
        );
        await storeProvider.addStore(store);
        await tester.pump();

        expect(find.text('Stores: $i'), findsOneWidget);
      }
    });

    testWidgets('SwipePageのSelector実装が正しく動作する', (tester) async {
      // SwipePageで使用される複合Selectorのテスト
      final testWidget = ChangeNotifierProvider<StoreProvider>.value(
        value: storeProvider,
        child: Scaffold(
          body: Selector<StoreProvider,
              ({bool isLoading, String? error, List<Store> stores})>(
            selector: (context, provider) => (
              isLoading: provider.isLoading,
              error: provider.error,
              stores: provider.stores,
            ),
            builder: (context, state, child) {
              return Column(
                children: [
                  Text('Loading: ${state.isLoading}'),
                  Text('Error: ${state.error ?? "None"}'),
                  Text('Stores: ${state.stores.length}'),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // 初期状態を確認
      expect(find.text('Loading: false'), findsOneWidget);
      expect(find.text('Error: None'), findsOneWidget);
      expect(find.text('Stores: 0'), findsOneWidget);

      // 店舗を追加
      final store = TestsHelper.createTestStore();
      await storeProvider.addStore(store);
      await tester.pump();

      // 状態が更新されていることを確認
      expect(find.text('Stores: 1'), findsOneWidget);
    });
  });
}
