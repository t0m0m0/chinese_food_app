import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/store_utils.dart';
import '../../../core/di/di_container_interface.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/get_visit_records_by_store_id_usecase.dart';
import '../../providers/store_provider.dart';
import '../../widgets/common_states.dart';
import '../store_detail/store_detail_page.dart';

class MyMenuPage extends StatefulWidget {
  const MyMenuPage({super.key});

  @override
  State<MyMenuPage> createState() => _MyMenuPageState();
}

class _MyMenuPageState extends State<MyMenuPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late GetVisitRecordsByStoreIdUsecase _getVisitRecordsUsecase;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // タブ切り替え時にデータを再読み込み & UI更新
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadStoresData();
        setState(() {}); // タブ色を更新するため
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Provider経由で設定済みのDIContainerを取得
      final container =
          Provider.of<DIContainerInterface>(context, listen: false);
      _getVisitRecordsUsecase = container.getGetVisitRecordsByStoreIdUsecase();
      _isInitialized = true;

      // 初回表示時に店舗データをDBから読み込み
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStoresData();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  // アプリのライフサイクル変化を監視（画面が前面に来た時にデータ再読み込み）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStoresData();
    }
  }

  void _loadStoresData() {
    if (mounted) {
      // ビルド完了後に非同期でデータ読み込み
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StoreProvider>(context, listen: false).loadStores();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecorativeElements.ramenBowl(size: 28),
                const SizedBox(width: 10),
                Text(
                  'マイメニュー',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                DecorativeElements.gyozaIcon(size: 28),
              ],
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: Column(
                children: [
                  DecorativeElements.norenDecoration(
                    height: 3,
                    color: AppTheme.primaryRed,
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: _getTabIndicatorColor(),
                    indicatorWeight: 3,
                    labelColor: _getTabIndicatorColor(),
                    unselectedLabelColor: AppTheme.textTertiary,
                    labelStyle: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTheme.labelMedium,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.favorite_rounded, size: 20),
                        text: '行きたい (${provider.wantToGoStores.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        text: '行った (${provider.visitedStores.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.block_rounded, size: 20),
                        text: '興味なし (${provider.badStores.length})',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: _buildBody(context, provider, theme, colorScheme),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    StoreProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (provider.isLoading) {
      return const AppLoadingState(message: '店舗データを読み込み中...');
    }

    if (provider.error != null) {
      return AppErrorState(
        message: provider.error,
        onRetry: () {
          Provider.of<StoreProvider>(context, listen: false).clearError();
          Provider.of<StoreProvider>(context, listen: false).refreshCache();
        },
      );
    }

    // マイメニュー画面では情報メッセージを表示しない
    // （infoMessageはスワイプ画面専用のAPI検索結果メッセージ）

    return TabBarView(
      controller: _tabController,
      children: [
        _buildStoreList(
          stores: provider.wantToGoStores,
          emptyMessage: 'まだ「行きたい」店舗がありません',
          emptySubMessage: '「見つける」画面で気になる店舗を右スワイプしてみましょう',
          emptyIcon: Icons.favorite_border,
          theme: theme,
          colorScheme: colorScheme,
        ),
        _buildStoreList(
          stores: provider.visitedStores,
          emptyMessage: 'まだ訪問した店舗がありません',
          emptySubMessage: '店舗を訪問したらステータスを更新しましょう',
          emptyIcon: Icons.check_circle_outline,
          theme: theme,
          colorScheme: colorScheme,
        ),
        _buildStoreList(
          stores: provider.badStores,
          emptyMessage: '「興味なし」の店舗はありません',
          emptySubMessage: '興味のない店舗はここに表示されます',
          emptyIcon: Icons.block_outlined,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildStoreList({
    required List<Store> stores,
    required String emptyMessage,
    required String emptySubMessage,
    required IconData emptyIcon,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    if (stores.isEmpty) {
      return AppEmptyState(
        message: emptyMessage,
        subMessage: emptySubMessage,
        icon: DecorativeElements.gyozaIcon(size: 64),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey('menu_${store.id}_$index'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index.clamp(0, 10) * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildStoreCard(store, theme, colorScheme),
        );
      },
    );
  }

  Widget _buildStoreCard(
      Store store, ThemeData theme, ColorScheme colorScheme) {
    final statusColor = StoreUtils.getStatusColor(store.status, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.accentBeige, width: 1),
      ),
      color: AppTheme.surfaceWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailPage(store: store),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左端のステータスカラーアクセントバー
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // メインコンテンツ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              StoreUtils.getStatusIcon(store.status),
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  style: AppTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppTheme.textTertiary,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        store.address,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                // 訪問済み店舗の場合、訪問回数を表示
                                if (store.status == StoreStatus.visited) ...[
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: _getVisitCount(store.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data! > 0) {
                                        return DecorativeElements.retroBadge(
                                          text: '${snapshot.data}回訪問',
                                          backgroundColor: AppTheme.successGreen
                                              .withValues(alpha: 0.1),
                                          textColor: AppTheme.successGreen,
                                          fontSize: 10,
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (store.memo?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCream,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentBeige,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            store.memo!,
                            style: AppTheme.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(store.createdAt),
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          PopupMenuButton<StoreStatus>(
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: AppTheme.textTertiary,
                              size: 20,
                            ),
                            onSelected: (newStatus) {
                              _updateStoreStatus(store.id, newStatus);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: StoreStatus.wantToGo,
                                child: Row(
                                  children: [
                                    Icon(Icons.favorite,
                                        color: AppTheme.primaryRed, size: 20),
                                    SizedBox(width: 8),
                                    Text('行きたい'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: StoreStatus.visited,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: AppTheme.successGreen, size: 20),
                                    SizedBox(width: 8),
                                    Text('行った'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: StoreStatus.bad,
                                child: Row(
                                  children: [
                                    Icon(Icons.block,
                                        color: AppTheme.warningOrange,
                                        size: 20),
                                    SizedBox(width: 8),
                                    Text('興味なし'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return StoreUtils.formatDate(date);
  }

  /// 現在選択されているタブに応じたインジケーター色を返す
  Color _getTabIndicatorColor() {
    switch (_tabController.index) {
      case 0:
        return AppTheme.statusWantToGo;
      case 1:
        return AppTheme.statusVisited;
      case 2:
        return AppTheme.statusBad;
      default:
        return AppTheme.statusWantToGo;
    }
  }

  /// 店舗の訪問回数を取得
  Future<int> _getVisitCount(String storeId) async {
    try {
      final visitRecords = await _getVisitRecordsUsecase.call(storeId);
      return visitRecords.length;
    } catch (e) {
      developer.log(
        'Failed to get visit count for store $storeId',
        name: 'MyMenuPage',
        error: e,
      );
      return 0;
    }
  }

  Future<void> _updateStoreStatus(String storeId, StoreStatus newStatus) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      await storeProvider.updateStoreStatus(storeId, newStatus);

      // ステータス更新成功 - UIの変化で十分なためスナックバー削除
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ErrorMessageHelper.getStoreRelatedMessage('update_status')),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
