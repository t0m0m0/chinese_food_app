import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../providers/store_provider.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final CardSwiperController controller = CardSwiperController();
  List<Store> _availableStores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoresFromProvider();
    });
  }

  /// Providerから店舗データを読み込み、未選択の店舗のみを表示対象とする
  void _loadStoresFromProvider() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // 既存の店舗データを読み込み
    storeProvider.loadStores().then((_) {
      // APIから新しい店舗データも取得
      return storeProvider.loadNewStoresFromApi(
        // テスト環境では現在地を使用（実際の実装では位置情報サービスを使用）
        lat: 35.6917,
        lng: 139.7006,
        count: 10,
      );
    }).then((_) {
      if (mounted) {
        _updateAvailableStores();
      }
    });
  }

  /// 利用可能な店舗リストを更新（状態が未設定の店舗のみ）
  void _updateAvailableStores() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    setState(() {
      _availableStores =
          storeProvider.stores.where((store) => store.status == null).toList();
    });
  }

  /// プルトゥリフレッシュで新しい店舗データを取得
  Future<void> _refreshStores() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    await storeProvider.loadNewStoresFromApi(
      lat: 35.6917,
      lng: 139.7006,
      count: 10,
    );
    if (mounted) {
      _updateAvailableStores();
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex < _availableStores.length) {
      final store = _availableStores[previousIndex];

      if (direction == CardSwiperDirection.right) {
        // 右スワイプ → 「行きたい」
        _updateStoreStatus(store, StoreStatus.wantToGo);
      } else if (direction == CardSwiperDirection.left) {
        // 左スワイプ → 「興味なし」
        _updateStoreStatus(store, StoreStatus.bad);
      }
    }
    return true;
  }

  Future<void> _updateStoreStatus(Store store, StoreStatus status) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      await storeProvider.updateStoreStatus(store.id, status);
      debugPrint('店舗 ${store.name} のステータスを ${status.value} に更新');

      // Consumer<StoreProvider>が自動的に更新を処理するため、手動更新は不要

      // 成功時のフィードバック
      if (mounted) {
        final statusText = status == StoreStatus.wantToGo ? '行きたい' : '興味なし';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${store.name}を「$statusText」に追加しました'),
            backgroundColor:
                status == StoreStatus.wantToGo ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('店舗ステータス更新エラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 店舗情報を表示するカードウィジェットを構築
  ///
  /// Material Design 3準拠のデザインで、店舗名、住所、
  /// アイコンを美しいカードレイアウトで表示します。
  ///
  /// [store] 表示する店舗データ
  /// 戻り値: Material Design 3準拠のCardウィジェット
  Widget _buildStoreCard(Store store) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerLow,
              colorScheme.surfaceContainerHigh,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              store.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    store.address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('スワイプ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.thumb_down,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '← 興味なし',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '→ 行きたい',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.favorite,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<StoreProvider>(
              builder: (context, storeProvider, child) {
                if (storeProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('新しい店舗を読み込み中...'),
                      ],
                    ),
                  );
                }

                if (storeProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'エラーが発生しました',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          storeProvider.error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            storeProvider.clearError();
                            _loadStoresFromProvider();
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  );
                }

                return _availableStores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_satisfied,
                              size: 64,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'すべての店舗を確認済みです！',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '検索画面で新しい店舗を探してみましょう',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshStores,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CardSwiper(
                            controller: controller,
                            cardsCount: _availableStores.length,
                            onSwipe: _onSwipe,
                            cardBuilder: (context, index, percentThresholdX,
                                percentThresholdY) {
                              return _buildStoreCard(_availableStores[index]);
                            },
                          ),
                        ),
                      );
              },
            ),
          ),
          const Text('AppCardSwiper'), // テスト用テキスト
        ],
      ),
    );
  }
}
