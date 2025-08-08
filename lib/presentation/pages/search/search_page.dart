import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/duplicate_store_checker.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/services/location_service.dart';
import '../../providers/store_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/cached_store_image.dart';
import '../store_detail/store_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  late SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    // SearchProviderを初期化
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    _searchProvider = SearchProvider(
      storeProvider: storeProvider,
      locationService: locationService,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchProvider.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (!_searchProvider.useCurrentLocation &&
        _searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('住所を入力してください')),
      );
      return;
    }

    if (_searchProvider.useCurrentLocation) {
      await _searchProvider.performSearchWithCurrentLocation();
    } else {
      await _searchProvider.performSearch(
          address: _searchController.text.trim());
    }
  }

  /// 位置情報エラーダイアログを表示
  Future<void> _showLocationErrorDialog(String errorMessage) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置情報の取得に失敗しました'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('位置情報の権限を確認してください'),
              const SizedBox(height: 8),
              Text('エラー: $errorMessage'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('住所で検索する'),
              onPressed: () {
                Navigator.of(context).pop();
                _searchProvider.setUseCurrentLocation(false);
              },
            ),
            TextButton(
              child: const Text('設定を開く'),
              onPressed: () async {
                Navigator.of(context).pop();

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await AppSettings.openAppSettings(
                    type: AppSettingsType.location,
                  );
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('設定画面を開けませんでした。手動で設定をご確認ください。'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: _searchProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('検索'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            _buildSearchForm(),
            const Divider(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Selector<SearchProvider,
        ({bool useCurrentLocation, bool isLoading, bool isGettingLocation})>(
      selector: (context, provider) => (
        useCurrentLocation: provider.useCurrentLocation,
        isLoading: provider.isLoading,
        isGettingLocation: provider.isGettingLocation,
      ),
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('現在地で検索'),
                      value: true,
                      groupValue: state.useCurrentLocation,
                      onChanged: (value) {
                        _searchProvider.setUseCurrentLocation(value ?? true);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('住所で検索'),
                      value: false,
                      groupValue: state.useCurrentLocation,
                      onChanged: (value) {
                        _searchProvider
                            .setUseCurrentLocation(!(value ?? false));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!state.useCurrentLocation)
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '住所を入力',
                    hintText: '例: 東京都新宿区',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (state.isLoading || state.isGettingLocation)
                      ? null
                      : _performSearch,
                  icon: (state.isLoading || state.isGettingLocation)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text((state.isGettingLocation || state.isLoading)
                      ? (state.isGettingLocation ? '現在地取得中...' : '検索中...')
                      : '中華料理店を検索'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Selector<
        SearchProvider,
        ({
          bool isGettingLocation,
          bool isLoading,
          String? errorMessage,
          List<Store> searchResults,
          bool hasSearched
        })>(
      selector: (context, provider) => (
        isGettingLocation: provider.isGettingLocation,
        isLoading: provider.isLoading,
        errorMessage: provider.errorMessage,
        searchResults: provider.searchResults,
        hasSearched: provider.hasSearched,
      ),
      builder: (context, state, child) {
        if (state.isGettingLocation) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('現在地取得中...'),
              ],
            ),
          );
        }

        if (state.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('検索中...'),
              ],
            ),
          );
        }

        if (state.errorMessage != null) {
          // 位置情報エラーの場合はダイアログを表示
          if (state.errorMessage!.contains('位置情報')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showLocationErrorDialog(state.errorMessage!);
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(state.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }

        if (state.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  state.hasSearched ? '検索結果が見つかりません' : '検索ボタンを押して中華料理店を探しましょう',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (state.hasSearched) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '別の住所で検索するか、\n検索範囲を広げてみてください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: state.searchResults.length,
          itemBuilder: (context, index) {
            final store = state.searchResults[index];
            return _buildStoreCard(store);
          },
        );
      },
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: CachedStoreImage(
            imageUrl: store.imageUrl,
            width: 56,
            height: 56,
            borderRadius: 28,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          store.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.address),
            if (store.memo?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                store.memo!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Selector<StoreProvider, List<Store>>(
          selector: (context, provider) => provider.stores,
          builder: (context, stores, child) {
            final existingStore = stores
                .where(
                    (s) => s.name == store.name && s.address == store.address)
                .firstOrNull;

            if (existingStore != null) {
              return Icon(
                _getStatusIcon(existingStore.status),
                color: _getStatusColor(existingStore.status),
              );
            }

            return IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () => _addToWantToGo(store),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailPage(store: store),
            ),
          );
        },
      ),
    );
  }

  /// 検索結果の店舗を「行きたい」リストに追加
  Future<void> _addToWantToGo(Store store) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // Issue #96: 統一化されたDuplicateStoreCheckerを使用
    final existingStore = storeProvider.stores
        .where((s) => DuplicateStoreChecker.isDuplicate(s, store))
        .firstOrNull;

    if (existingStore != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ErrorMessageHelper.getStoreRelatedMessage('duplicate_store')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // 検索結果の店舗をステータス付きで追加
      final storeWithStatus = store.copyWith(status: StoreStatus.wantToGo);
      await storeProvider.addStore(storeWithStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${store.name}を「行きたい」に追加しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ErrorMessageHelper.getStoreRelatedMessage('add_store')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColor(StoreStatus? status) {
    final colorScheme = Theme.of(context).colorScheme;
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
}
