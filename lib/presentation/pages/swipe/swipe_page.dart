import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/config/distance_config_manager.dart';
import '../../../core/config/search_config.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/services/location_service.dart';
import '../../providers/store_provider.dart';
import '../../widgets/cached_store_image.dart';
import '../../widgets/distance_selector_widget.dart';
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
  int _selectedRange = SearchConfig.defaultRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedDistance();
      _loadStoresFromProvider();
    });
  }

  /// 保存された距離設定を読み込む
  Future<void> _loadSavedDistance() async {
    final savedRange = await DistanceConfigManager.getDistance();
    setState(() {
      _selectedRange = savedRange;
    });
  }

  /// 距離設定を変更し、店舗を再読み込み
  Future<void> _onDistanceChanged(int newRange) async {
    if (newRange == _selectedRange) return;

    setState(() {
      _selectedRange = newRange;
    });

    // 設定を保存
    await DistanceConfigManager.saveDistance(newRange);

    // 店舗を再読み込み
    await _loadStoresWithLocation();

    if (mounted) {
      final meters = SearchConfig.rangeToMeter(newRange) ?? 1000;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('検索範囲を${meters}mに変更しました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        range: _selectedRange,
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
        range: _selectedRange,
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
        range: _selectedRange,
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
    final allStores = storeProvider.stores;
    final availableStores =
        allStores.where((store) => store.status == null).toList();

    debugPrint('📋 _updateAvailableStores() 実行:');
    debugPrint('  📊 全店舗数: ${allStores.length}件');
    debugPrint('  🎯 利用可能店舗(status==null): ${availableStores.length}件');

    if (allStores.isNotEmpty) {
      debugPrint('  📋 全店舗のステータス分布:');
      final wantToGo =
          allStores.where((s) => s.status == StoreStatus.wantToGo).length;
      final visited =
          allStores.where((s) => s.status == StoreStatus.visited).length;
      final bad = allStores.where((s) => s.status == StoreStatus.bad).length;
      final nullStatus = allStores.where((s) => s.status == null).length;
      debugPrint('    - wantToGo: $wantToGo件');
      debugPrint('    - visited: $visited件');
      debugPrint('    - bad: $bad件');
      debugPrint('    - null(未選択): $nullStatus件');
    }

    setState(() {
      _availableStores = availableStores;
    });

    debugPrint('  ✅ _availableStoresに設定完了: ${_availableStores.length}件');
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

      // カード残り枚数チェック - API呼び出しを制限
      final remainingCards = _availableStores.length - (previousIndex + 1);
      debugPrint(
          '🃏 カード残り枚数: $remainingCards件 (previousIndex: $previousIndex)');

      // 残り2枚以下でかつ既に十分な店舗データがある場合は新規API呼び出しを行わない
      if (remainingCards <= 2) {
        final storeProvider =
            Provider.of<StoreProvider>(context, listen: false);
        final totalStores = storeProvider.stores.length;

        debugPrint('⚠️ カード残り少数警告: 残り$remainingCards枚, 総店舗数: $totalStores件');

        // 総店舗数が20件以上ある場合は追加API呼び出しを抑制
        if (totalStores >= 20) {
          debugPrint('🚫 API呼び出し抑制: 十分な店舗データが存在');
        } else {
          debugPrint('📡 新規API呼び出し許可: データが不足している');
          // Future.microtaskを使用して現在のbuild cycleの後でAPI呼び出し
          Future.microtask(() {
            if (mounted) {
              _loadStoresWithLocation();
            }
          });
        }
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
        // Issue #111 修正: より詳細なエラー情報とリカバリー機能を提供
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () async {
                // データベースリカバリーを試行
                final success =
                    await storeProvider.tryRecoverFromDatabaseError();
                if (success && mounted) {
                  // リカバリー成功後、再度ステータス更新を試行
                  await _updateStoreStatus(store, status);
                }
              },
            ),
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

    return RepaintBoundary(
      child: Card(
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
            padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // 店舗画像表示（パフォーマンス最適化済み）
                RepaintBoundary(
                  child: CachedStoreImage(
                    imageUrl: store.imageUrl,
                    width: 100,
                    height: 100,
                    borderRadius: 50, // 円形にするため幅/高さの半分
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  store.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
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
      ), // RepaintBoundaryの閉じ括弧
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
          // 距離設定UI
          DistanceSelectorWidget(
            selectedRange: _selectedRange,
            onChanged: _onDistanceChanged,
          ),
          // スワイプ操作説明
          RepaintBoundary(
            child: Container(
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
                : Selector<
                    StoreProvider,
                    ({
                      bool isLoading,
                      String? error,
                      String? infoMessage,
                      List<Store> stores
                    })>(
                    selector: (context, provider) => (
                      isLoading: provider.isLoading,
                      error: provider.error,
                      infoMessage: provider.infoMessage,
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

                      // 情報メッセージ表示（検索結果0件など）
                      if (state.infoMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '検索結果',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.infoMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Provider.of<StoreProvider>(context,
                                          listen: false)
                                      .clearError(); // 情報メッセージもクリア
                                  _loadStoresFromProvider();
                                },
                                child: const Text('別の場所で検索'),
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
                                    // IndexOutOfRangeエラーを防ぐための安全チェック
                                    if (index < 0 ||
                                        index >= _availableStores.length) {
                                      debugPrint(
                                          '⚠️ CardSwiper index out of range: $index, available: ${_availableStores.length}');
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'カードの読み込みエラー',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color:
                                                  colorScheme.onErrorContainer,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return _buildStoreCard(
                                        _availableStores[index]);
                                  },
                                ),
                              ),
                            );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
