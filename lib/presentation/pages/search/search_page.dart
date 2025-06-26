import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../data/datasources/hotpepper_api_datasource.dart';
import '../../../data/repositories/store_repository_impl.dart';
import '../../../data/datasources/store_local_datasource.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/usecases/search_stores_usecase.dart';
import '../../../domain/entities/store.dart';
import '../../../services/location_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();

  List<Store> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _useCurrentLocation = true;
  bool _hasSearched = false; // 検索が実行されたかどうかのフラグ

  late final SearchStoresUsecase _searchUsecase;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // 本番環境ではAPIキーが設定されている場合のみ実API使用
    final HotpepperApiDatasource apiDatasource;
    if (AppConfig.hasHotpepperApiKey && AppConfig.isProduction) {
      apiDatasource = HotpepperApiDatasourceImpl(
        client: http.Client(),
      );
    } else {
      // 開発環境またはAPIキー未設定時はモック使用
      apiDatasource = MockHotpepperApiDatasource();
    }

    final localDatasource = StoreLocalDatasourceImpl(dbHelper: DatabaseHelper());
    final repository = StoreRepositoryImpl(
      apiDatasource: apiDatasource,
      localDatasource: localDatasource,
    );
    _searchUsecase = SearchStoresUsecase(repository);
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
      SearchStoresParams params;

      if (_useCurrentLocation) {
        final locationResult = await _locationService.getCurrentPosition();
        if (!locationResult.isSuccess) {
          setState(() {
            _errorMessage = locationResult.error;
            _isLoading = false;
          });
          return;
        }

        params = SearchStoresParams(
          lat: locationResult.lat,
          lng: locationResult.lng,
          keyword: '中華',
        );
      } else {
        params = SearchStoresParams(
          address: _searchController.text.trim(),
          keyword: '中華',
        );
      }

      final result = await _searchUsecase.execute(params);

      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _searchResults = result.stores ?? [];
          // 座標フィルタリングで結果が空になった場合の追加情報
          if (_searchResults.isEmpty) {
            _errorMessage = '検索範囲内に有効な座標を持つ店舗が見つかりませんでした。';
          }
        } else {
          _errorMessage = result.error;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
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
              onPressed: _isLoading ? null : _performSearch,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? '検索中...' : '中華料理店を検索'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
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
        trailing: IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${store.name}を「行きたい」に追加しました')),
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
}
