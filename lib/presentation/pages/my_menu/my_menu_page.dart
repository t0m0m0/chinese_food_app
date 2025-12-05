import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/di/di_container_interface.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/get_visit_records_by_store_id_usecase.dart';
import '../../providers/store_provider.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecorativeElements.ramenBowl(size: 30),
            const SizedBox(width: 12),
            Text(
              'マイメニュー',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            DecorativeElements.gyozaIcon(size: 30),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _getTabIndicatorColor(),
          indicatorWeight: 3,
          labelColor: _getTabIndicatorColor(),
          unselectedLabelColor: AppTheme.textTertiary,
          labelStyle: AppTheme.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTheme.labelMedium,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite_rounded),
              text: '行きたい',
            ),
            Tab(
              icon: Icon(Icons.check_circle_rounded),
              text: '行った',
            ),
            Tab(
              icon: Icon(Icons.block_rounded),
              text: '興味なし',
            ),
          ],
        ),
      ),
      body: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('店舗データを読み込み中...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
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
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<StoreProvider>(context, listen: false)
                          .clearError();
                      // エラークリア後にキャッシュをリフレッシュ
                      Provider.of<StoreProvider>(context, listen: false)
                          .refreshCache();
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
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
        },
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => _showDebugMenu(context),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.bug_report),
              label: const Text('デバッグ'),
            )
          : null,
    );
  }

  /// デバッグメニューを表示
  void _showDebugMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 デバッグメニュー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '開発者向け機能',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            Consumer<StoreProvider>(
              builder: (context, provider, child) {
                final count = provider.stores.length;
                final wantToGo = provider.wantToGoStores.length;
                final visited = provider.visitedStores.length;
                final bad = provider.badStores.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 DB内の店舗数: $count件'),
                    const SizedBox(height: 4),
                    Text('  • 行きたい: $wantToGo件'),
                    Text('  • 行った: $visited件'),
                    Text('  • 興味なし: $bad件'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () => _deleteAllStores(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('全店舗削除'),
          ),
        ],
      ),
    );
  }

  /// 全店舗削除を実行
  Future<void> _deleteAllStores(BuildContext context) async {
    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認'),
        content: const Text(
          'すべての店舗データを削除します。\nこの操作は取り消せません。\n\n本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // ダイアログを閉じる
    Navigator.pop(context);

    // 削除実行
    final provider = Provider.of<StoreProvider>(context, listen: false);
    await provider.deleteAllStores();

    if (!context.mounted) return;

    // 完了メッセージ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 全店舗データを削除しました'),
        backgroundColor: Colors.green,
      ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return _buildStoreCard(store, theme, colorScheme);
      },
    );
  }

  Widget _buildStoreCard(
      Store store, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailPage(store: store),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(store.status, colorScheme)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(store.status),
                      color: _getStatusColor(store.status, colorScheme),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
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
                              if (snapshot.hasData && snapshot.data! > 0) {
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${snapshot.data}回訪問',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    store.memo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(store.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  PopupMenuButton<StoreStatus>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (newStatus) {
                      _updateStoreStatus(store.id, newStatus);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: StoreStatus.wantToGo,
                        child: Row(
                          children: [
                            Icon(Icons.favorite),
                            SizedBox(width: 8),
                            Text('行きたい'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: StoreStatus.visited,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text('行った'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: StoreStatus.bad,
                        child: Row(
                          children: [
                            Icon(Icons.block),
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
    );
  }

  Color _getStatusColor(StoreStatus? status, ColorScheme colorScheme) {
    switch (status) {
      case StoreStatus.wantToGo:
        return Colors.red;
      case StoreStatus.visited:
        return Colors.green;
      case StoreStatus.bad:
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(StoreStatus? status) {
    switch (status) {
      case StoreStatus.wantToGo:
        return Icons.favorite;
      case StoreStatus.visited:
        return Icons.check_circle;
      case StoreStatus.bad:
        return Icons.block;
      default:
        return Icons.restaurant;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// 現在選択されているタブに応じたインジケーター色を返す
  Color _getTabIndicatorColor() {
    switch (_tabController.index) {
      case 0: // 行きたい
        return Colors.red;
      case 1: // 行った
        return Colors.green;
      case 2: // 興味なし
        return Colors.orange;
      default:
        return Colors.red;
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
