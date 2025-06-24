import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../../domain/entities/store.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final CardSwiperController controller = CardSwiperController();
  List<Store> stores = [];

  @override
  void initState() {
    super.initState();
    _loadSampleStores();
  }

  void _loadSampleStores() {
    // サンプルデータ（将来的にはrepositoryから取得）
    final now = DateTime.now();
    stores = [
      Store(
        id: '1',
        name: '中華料理 龍',
        address: '東京都渋谷区1-1-1',
        lat: 35.6621,
        lng: 139.7038,
        createdAt: now,
      ),
      Store(
        id: '2',
        name: '餃子の王将',
        address: '東京都新宿区2-2-2',
        lat: 35.6938,
        lng: 139.7036,
        createdAt: now,
      ),
      Store(
        id: '3',
        name: '町中華 味楽',
        address: '東京都世田谷区3-3-3',
        lat: 35.6462,
        lng: 139.6503,
        createdAt: now,
      ),
    ];
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex < stores.length) {
      final store = stores[previousIndex];

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
    try {
      // TODO: repositoryを使用してデータベースに保存
      // final updatedStore = store.copyWith(status: status);
      // 将来的にはrepository.updateStore(updatedStore)を呼ぶ

      debugPrint('店舗 ${store.name} のステータスを ${status.value} に更新');

      // 成功時の処理（スナックバーなど）を追加可能
    } catch (e) {
      // エラーハンドリング
      debugPrint('店舗ステータス更新エラー: $e');

      // ユーザーへのエラー表示（スナックバーなど）を追加可能
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
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
            child: stores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_neutral,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'カードがありません',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: stores.length,
                      onSwipe: _onSwipe,
                      cardBuilder: (context, index, percentThresholdX,
                          percentThresholdY) {
                        return _buildStoreCard(stores[index]);
                      },
                    ),
                  ),
          ),
          const Text('AppCardSwiper'), // テスト用テキスト
        ],
      ),
    );
  }
}
