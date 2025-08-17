import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../providers/store_provider.dart';
import '../store_detail/store_detail_page.dart';

class MyMenuPage extends StatefulWidget {
  const MyMenuPage({super.key});

  @override
  State<MyMenuPage> createState() => _MyMenuPageState();
}

class _MyMenuPageState extends State<MyMenuPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 店舗データは事前初期化済みのため、利用可能な店舗リストを更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // キャッシュをリフレッシュして最新状態を反映
      Provider.of<StoreProvider>(context, listen: false).refreshCache();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイメニュー'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: '行きたい',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: '行った',
            ),
            Tab(
              icon: Icon(Icons.block),
              text: '興味なし',
            ),
          ],
        ),
      ),
      body: Selector<
          StoreProvider,
          ({
            bool isLoading,
            String? error,
            String? infoMessage,
            List<Store> wantToGoStores,
            List<Store> visitedStores,
            List<Store> badStores
          })>(
        selector: (context, provider) => (
          isLoading: provider.isLoading,
          error: provider.error,
          infoMessage: provider.infoMessage,
          wantToGoStores: provider.wantToGoStores,
          visitedStores: provider.visitedStores,
          badStores: provider.badStores,
        ),
        builder: (context, state, child) {
          if (state.isLoading) {
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

          if (state.error != null) {
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
                    state.error!,
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

          // 情報メッセージ表示
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
                    'お知らせ',
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
                      Provider.of<StoreProvider>(context, listen: false)
                          .clearError(); // 情報メッセージもクリア
                    },
                    child: const Text('了解'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildStoreList(
                stores: state.wantToGoStores,
                emptyMessage: 'まだ「行きたい」店舗がありません',
                emptySubMessage: 'スワイプ画面で気になる店舗を右スワイプしてみましょう',
                emptyIcon: Icons.favorite_border,
                theme: theme,
                colorScheme: colorScheme,
              ),
              _buildStoreList(
                stores: state.visitedStores,
                emptyMessage: 'まだ訪問した店舗がありません',
                emptySubMessage: '店舗を訪問したらステータスを更新しましょう',
                emptyIcon: Icons.check_circle_outline,
                theme: theme,
                colorScheme: colorScheme,
              ),
              _buildStoreList(
                stores: state.badStores,
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
        return colorScheme.primary;
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
