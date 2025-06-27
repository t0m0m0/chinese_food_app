import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/services/location_service.dart';
import '../../providers/store_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  List<Store> _searchResults = [];
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  bool _useCurrentLocation = true;
  bool _hasSearched = false; // 検索が実行されたかどうかのフラグ

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (!_useCurrentLocation && _searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('住所を入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults.clear();
      _hasSearched = true;
    });

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);

      if (_useCurrentLocation) {
        // 位置情報を取得してAPI検索
        await _searchWithCurrentLocation(storeProvider);
      } else {
        // 住所を使ってAPI検索
        await storeProvider.loadNewStoresFromApi(
          address: _searchController.text.trim(),
          keyword: '中華',
        );
        
        setState(() {
          // 新しく追加された店舗を検索結果として表示
          _searchResults = storeProvider.newStores;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// 現在位置を取得してAPI検索を実行
  Future<void> _searchWithCurrentLocation(StoreProvider storeProvider) async {
    try {
      setState(() {
        _isGettingLocation = true;
      });

      // 位置情報サービスを取得（Providerから注入）
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // 現在位置を取得
      final location = await locationService.getCurrentLocation();
      
      setState(() {
        _isGettingLocation = false;
      });

      // 位置情報を使ってAPI検索
      await storeProvider.loadNewStoresFromApi(
        lat: location.latitude,
        lng: location.longitude,
        keyword: '中華',
      );
      
      setState(() {
        // 新しく追加された店舗を検索結果として表示
        _searchResults = storeProvider.newStores;
        _isLoading = false;
      });
      
    } on LocationException catch (e) {
      setState(() {
        _isGettingLocation = false;
        _isLoading = false;
      });

      // 位置情報エラーダイアログを表示
      await _showLocationErrorDialog(e);
      
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// 位置情報エラーダイアログを表示
  Future<void> _showLocationErrorDialog(LocationException error) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置情報の取得に失敗しました'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('位置情報の権限を確認してください'),
              const SizedBox(height: 8),
              Text('エラー: ${error.message}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('住所で検索する'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _useCurrentLocation = false;
                });
              },
            ),
            TextButton(
              child: const Text('設定を開く'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 設定画面を開く実装
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('設定画面は実装予定です')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildSearchForm() {
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
                  groupValue: _useCurrentLocation,
                  onChanged: (value) {
                    setState(() {
                      _useCurrentLocation = value ?? true;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('住所で検索'),
                  value: false,
                  groupValue: _useCurrentLocation,
                  onChanged: (value) {
                    setState(() {
                      _useCurrentLocation = !(value ?? false);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_useCurrentLocation)
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
              onPressed: (_isLoading || _isGettingLocation) ? null : _performSearch,
              icon: (_isLoading || _isGettingLocation)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text((_isGettingLocation || _isLoading)
                ? (_isGettingLocation ? '現在地取得中...' : '検索中...')
                : '中華料理店を検索'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isGettingLocation) {
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

    if (_isLoading) {
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

    if (_errorMessage != null) {
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
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _hasSearched ? '検索結果が見つかりません' : '検索ボタンを押して中華料理店を探しましょう',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_hasSearched) ...[
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final store = _searchResults[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.restaurant),
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
        trailing: Consumer<StoreProvider>(
          builder: (context, storeProvider, child) {
            final existingStore = storeProvider.stores
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
          // TODO: 店舗詳細画面への遷移
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${store.name}の詳細画面は実装予定です')),
          );
        },
      ),
    );
  }

  /// 検索結果の店舗を「行きたい」リストに追加
  Future<void> _addToWantToGo(Store store) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // 重複チェック
    final existingStore = storeProvider.stores
        .where((s) => s.name == store.name && s.address == store.address)
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
