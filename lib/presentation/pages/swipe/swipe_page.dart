import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/services/location_service.dart';
import '../../providers/store_provider.dart';
import '../../widgets/cached_store_image.dart';
import '../store_detail/store_detail_page.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final CardSwiperController controller = CardSwiperController();
  List<Store> _availableStores = [];
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoresFromProvider();
    });
  }

  /// Providerから店舗データを読み込み、未選択の店舗のみを表示対象とする
  void _loadStoresFromProvider() async {
    // 既存の店舗データは事前初期化済みのため、APIから新しい店舗データのみ取得
    await _loadStoresWithLocation();
  }

  /// 位置情報を取得してAPIから店舗データを読み込む
  Future<void> _loadStoresWithLocation() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      setState(() {
        _isGettingLocation = true;
        _locationError = null;
      });

      // 位置情報サービスを取得（Providerから注入）
      final locationService =
          Provider.of<LocationService>(context, listen: false);

      // 現在位置を取得
      final location = await locationService.getCurrentLocation();

      // 位置情報を使ってAPI検索
      await storeProvider.loadNewStoresFromApi(
        lat: location.latitude,
        lng: location.longitude,
        count: ApiConstants.defaultStoreCount,
      );
    } on LocationException {
      // 位置情報エラーをキャッチし、フォールバック処理
      setState(() {
        _locationError = '位置情報の取得に失敗しました';
      });

      // フォールバック: デフォルト位置で検索
      await storeProvider.loadNewStoresFromApi(
        lat: ApiConstants.defaultLatitude,
        lng: ApiConstants.defaultLongitude,
        count: ApiConstants.defaultStoreCount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('デフォルトの場所で検索しています'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // その他のエラー
      setState(() {
        _locationError = 'エラーが発生しました: $e';
      });

      // フォールバック: デフォルト位置で検索
      await storeProvider.loadNewStoresFromApi(
        lat: ApiConstants.defaultLatitude,
        lng: ApiConstants.defaultLongitude,
        count: ApiConstants.defaultStoreCount,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
        _updateAvailableStores();
      }
    }
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
    // 位置情報を再取得してAPIから店舗データを更新
    await _loadStoresWithLocation();
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailPage(store: store),
            ),
          );
        },
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
              // 店舗画像表示
              CachedStoreImage(
                imageUrl: store.imageUrl,
                width: 120,
                height: 120,
                borderRadius: 60, // 円形にするため幅/高さの半分
                fit: BoxFit.cover,
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
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'タップで詳細を表示',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
            child: _isGettingLocation
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('現在地を取得中...'),
                      ],
                    ),
                  )
                : Selector<StoreProvider,
                    ({bool isLoading, String? error, List<Store> stores})>(
                    selector: (context, provider) => (
                      isLoading: provider.isLoading,
                      error: provider.error,
                      stores: provider.stores,
                    ),
                    builder: (context, state, child) {
                      // API読み込み中の表示
                      if (state.isLoading) {
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

                      // エラー表示
                      final errorMessage = state.error ?? _locationError;
                      if (errorMessage != null) {
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
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Provider.of<StoreProvider>(context,
                                          listen: false)
                                      .clearError();
                                  setState(() {
                                    _locationError = null;
                                  });
                                  _loadStoresFromProvider();
                                },
                                child: const Text('再試行'),
                              ),
                            ],
                          ),
                        );
                      }

                      // カードスワイプ表示
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
                                  cardBuilder: (context, index,
                                      percentThresholdX, percentThresholdY) {
                                    return _buildStoreCard(
                                        _availableStores[index]);
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
