import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/search_config.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/services/location_service.dart';
import '../../providers/store_provider.dart';
import '../../widgets/swipe_card_widget.dart';
import '../../widgets/swipe_action_buttons.dart';
import '../../widgets/swipe_feedback_overlay.dart';
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

  // スワイプフィードバック用状態
  bool _showLikeFeedback = false;
  bool _showDislikeFeedback = false;

  // ページネーション用状態
  int _currentPage = 1;
  double? _lastLat;
  double? _lastLng;

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
    final savedRange = await AppConfig.search.getDistance();
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
    await AppConfig.search.saveDistance(newRange);

    // 店舗を再読み込み
    await _loadStoresWithLocation();
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

      // 位置情報を保存（ページネーション用）
      _lastLat = location.latitude;
      _lastLng = location.longitude;
      _currentPage = 1; // 新規読み込み時はページをリセット

      // 位置情報を使ってスワイプ画面専用API検索
      await storeProvider.loadSwipeStores(
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

      // フォールバック: デフォルト位置でスワイプ画面専用検索
      _lastLat = ApiConstants.defaultLatitude;
      _lastLng = ApiConstants.defaultLongitude;
      _currentPage = 1;

      await storeProvider.loadSwipeStores(
        lat: ApiConstants.defaultLatitude,
        lng: ApiConstants.defaultLongitude,
        range: _selectedRange,
        count: ApiConstants.defaultStoreCount,
      );

      // デフォルト位置使用 - _locationErrorで状態表示するためスナックバー削除
    } catch (e) {
      // その他のエラー
      setState(() {
        _locationError = 'エラーが発生しました: $e';
      });

      // フォールバック: デフォルト位置でスワイプ画面専用検索
      _lastLat = ApiConstants.defaultLatitude;
      _lastLng = ApiConstants.defaultLongitude;
      _currentPage = 1;

      await storeProvider.loadSwipeStores(
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

  /// 利用可能な店舗リストを更新（スワイプ画面専用の現在地周辺店舗のみ）
  void _updateAvailableStores() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final swipeStores = storeProvider.swipeStores; // スワイプ専用リストを使用
    final availableStores = swipeStores; // swipeStoresは既にstatus==nullでフィルタ済み

    setState(() {
      _availableStores = availableStores;
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
        _showSwipeFeedback(true);
        _updateStoreStatus(store, StoreStatus.wantToGo);
      } else if (direction == CardSwiperDirection.left) {
        // 左スワイプ → 「興味なし」
        _showSwipeFeedback(false);
        _updateStoreStatus(store, StoreStatus.bad);
      }

      // 自動ページネーション: 残り10枚以下になったら次ページを取得
      final remainingCards = _availableStores.length - (previousIndex + 1);
      if (remainingCards <= 10 && _lastLat != null && _lastLng != null) {
        debugPrint('[SwipePage] 📄 残り$remainingCards枚 → 次ページ取得開始');

        // Future.microtaskを使用して現在のbuild cycleの後でAPI呼び出し
        Future.microtask(() async {
          if (mounted) {
            final storeProvider =
                Provider.of<StoreProvider>(context, listen: false);

            // 次ページを計算
            _currentPage++;
            final nextStart =
                (_currentPage - 1) * ApiConstants.defaultStoreCount + 1;

            debugPrint(
                '[SwipePage] 📄 ページ$_currentPage (start=$nextStart) を取得');

            await storeProvider.loadMoreSwipeStores(
              lat: _lastLat!,
              lng: _lastLng!,
              range: _selectedRange,
              count: ApiConstants.defaultStoreCount,
              start: nextStart,
            );

            // スワイプリストが更新されたらUIを更新
            if (mounted) {
              _updateAvailableStores();
            }
          }
        });
      }
    }
    return true;
  }

  /// 手動「興味なし」ボタンアクション
  void _onManualDislike() {
    if (_availableStores.isNotEmpty) {
      controller.swipe(CardSwiperDirection.left);
    }
  }

  /// 手動「行きたい」ボタンアクション
  void _onManualLike() {
    if (_availableStores.isNotEmpty) {
      controller.swipe(CardSwiperDirection.right);
    }
  }

  /// フィードバック表示を管理
  void _showSwipeFeedback(bool isLike) {
    setState(() {
      if (isLike) {
        _showLikeFeedback = true;
        _showDislikeFeedback = false;
      } else {
        _showLikeFeedback = false;
        _showDislikeFeedback = true;
      }
    });

    // 1秒後にフィードバックを隠す
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showLikeFeedback = false;
          _showDislikeFeedback = false;
        });
      }
    });
  }

  Future<void> _updateStoreStatus(Store store, StoreStatus status) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      // スワイプ画面専用: 新規店舗でも既存店舗でも適切にDB保存
      await storeProvider.saveSwipedStore(store, status);
      // Consumer<StoreProvider>が自動的に更新を処理するため、手動更新は不要
    } catch (e) {
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

  /// 店舗が見つからない場合の空状態UIを構築
  ///
  /// 店舗リストが空の時に表示される共通のメッセージUI
  ///
  /// [theme] アプリのテーマデータ
  /// [colorScheme] カラースキーム
  /// 戻り値: 空状態を示すCenterウィジェット
  Widget _buildEmptyStoreMessage(ThemeData theme, ColorScheme colorScheme) {
    return Center(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'スワイプ',
          style: AppTheme.headlineMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        elevation: 0,
      ),
      body: DecorativeElements.foodPatternBackground(
        opacity: 0.03,
        child: Column(
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
                        const Icon(
                          Icons.block,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '← 興味なし',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
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
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
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
                              ],
                            ),
                          );
                        }

                        // スワイプ可能な店舗の表示制御（競合状態防止）
                        // アトミックな参照により一貫性を保証
                        final currentStores =
                            List<Store>.from(_availableStores);
                        final hasStores = currentStores.isNotEmpty;

                        return !hasStores
                            ? _buildEmptyStoreMessage(theme, colorScheme)
                            : RefreshIndicator(
                                onRefresh: _refreshStores,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  // CardSwiper初期化防護: 競合状態による cardsCount=0 防止
                                  // アトミック参照により堅牢性確保（Issue #130根本対応）
                                  child: hasStores
                                      ? Stack(
                                          children: [
                                            CardSwiper(
                                              controller: controller,
                                              cardsCount: currentStores.length,
                                              numberOfCardsDisplayed: math.min(
                                                  currentStores.length, 3),
                                              onSwipe: _onSwipe,
                                              cardBuilder: (context,
                                                  index,
                                                  percentThresholdX,
                                                  percentThresholdY) {
                                                // IndexOutOfRangeエラーを防ぐための安全チェック
                                                if (index < 0 ||
                                                    index >=
                                                        currentStores.length) {
                                                  debugPrint(
                                                      '⚠️ CardSwiper index out of range: $index, available: ${currentStores.length}');
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: colorScheme
                                                          .errorContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'カードの読み込みエラー',
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onErrorContainer,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return SwipeCardWidget(
                                                  store: currentStores[index],
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            StoreDetailPage(
                                                                store:
                                                                    currentStores[
                                                                        index]),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            // スワイプフィードバックオーバーレイ
                                            SwipeFeedbackOverlay(
                                              showLike: _showLikeFeedback,
                                              showDislike: _showDislikeFeedback,
                                            ),
                                          ],
                                        )
                                      // フォールバック: 極端な競合状態での安全なUI表示
                                      // （理論上発生しないが、Web環境での予期しない状態変化に対応）
                                      : _buildEmptyStoreMessage(
                                          theme, colorScheme),
                                ),
                              );
                      },
                    ),
            ),
            // 手動操作ボタン
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SwipeActionButtons(
                onDislike: _onManualDislike,
                onLike: _onManualLike,
                enabled: _availableStores.isNotEmpty && !_isGettingLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
