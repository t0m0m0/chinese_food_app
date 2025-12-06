import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/duplicate_store_checker.dart';
import '../../../core/constants/area_data.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/area.dart';
import '../../providers/store_provider.dart';
import '../../providers/area_search_provider.dart';
import '../../widgets/cached_store_image.dart';
import '../../widgets/api_attribution_widget.dart';
import '../store_detail/store_detail_page.dart';

/// エリア探索ページ
///
/// 都道府県・市区町村の階層選択によるエリア指定検索を提供
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late AreaSearchProvider _areaSearchProvider;

  @override
  void initState() {
    super.initState();
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    _areaSearchProvider = AreaSearchProvider(storeProvider: storeProvider);
  }

  @override
  void dispose() {
    _areaSearchProvider.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (!_areaSearchProvider.canSearch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('都道府県を選択してください')),
      );
      return;
    }
    await _areaSearchProvider.performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AreaSearchProvider>.value(
      value: _areaSearchProvider,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecorativeElements.lanternDecoration(
                  size: 50, color: AppTheme.primaryRed),
              const SizedBox(width: 12),
              Text(
                'エリア',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              DecorativeElements.lanternDecoration(
                  size: 50, color: AppTheme.secondaryYellow),
            ],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primaryRed),
        ),
        body: Column(
          children: [
            _buildAreaSelector(),
            Divider(color: AppTheme.accentBeige.withValues(alpha: 0.5)),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaSelector() {
    return Selector<AreaSearchProvider,
        ({Prefecture? prefecture, City? city, bool isLoading})>(
      selector: (context, provider) => (
        prefecture: provider.selectedPrefecture,
        city: provider.selectedCity,
        isLoading: provider.isLoading,
      ),
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 都道府県選択
              _buildPrefectureSelector(state.prefecture),
              const SizedBox(height: 12),

              // 市区町村選択（都道府県選択後のみ表示）
              if (state.prefecture != null) ...[
                _buildCitySelector(state.prefecture!, state.city),
                const SizedBox(height: 12),
              ],

              // 選択中のエリア表示
              if (state.prefecture != null) _buildSelectedAreaChip(state),

              const SizedBox(height: 16),

              // 検索ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _performSearch,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(state.isLoading
                      ? '検索中...'
                      : StringConstants.searchButtonLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrefectureSelector(Prefecture? selectedPrefecture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '都道府県を選択',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showPrefectureDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentBeige),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedPrefecture?.name ?? '選択してください',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedPrefecture != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCitySelector(Prefecture prefecture, City? selectedCity) {
    final cities = AreaData.getCitiesForPrefecture(prefecture.code);

    if (cities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '市区町村を選択（任意）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCityDialog(prefecture),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentBeige),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCity?.name ?? '全域',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedCity != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    if (selectedCity != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _areaSearchProvider.clearCity(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down,
                        color: AppTheme.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedAreaChip(
      ({Prefecture? prefecture, City? city, bool isLoading}) state) {
    final selection = _areaSearchProvider.currentSelection;
    if (selection == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 18, color: AppTheme.primaryRed),
          const SizedBox(width: 4),
          Text(
            '${selection.displayName}の中華料理店',
            style: const TextStyle(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrefectureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('都道府県を選択'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: AreaData.prefecturesByRegion.length,
            itemBuilder: (context, index) {
              final region = AreaData.prefecturesByRegion.keys.elementAt(index);
              final prefectures = AreaData.prefecturesByRegion[region]!;

              return ExpansionTile(
                title: Text(
                  region,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: region == '関東', // 関東をデフォルトで開く
                children: prefectures.map((prefecture) {
                  return ListTile(
                    title: Text(prefecture.name),
                    dense: true,
                    onTap: () {
                      _areaSearchProvider.selectPrefecture(prefecture);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showCityDialog(Prefecture prefecture) {
    final cities = AreaData.getCitiesForPrefecture(prefecture.code);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${prefecture.name}の市区町村'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              ListTile(
                title: const Text('全域'),
                leading: const Icon(Icons.public),
                dense: true,
                onTap: () {
                  _areaSearchProvider.clearCity();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...cities.map((city) => ListTile(
                    title: Text(city.name),
                    dense: true,
                    onTap: () {
                      _areaSearchProvider.selectCity(city);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Selector<
        AreaSearchProvider,
        ({
          bool isLoading,
          String? errorMessage,
          List<Store> searchResults,
          bool hasSearched,
          AreaSelection? selection
        })>(
      selector: (context, provider) => (
        isLoading: provider.isLoading,
        errorMessage: provider.errorMessage,
        searchResults: provider.searchResults,
        hasSearched: provider.hasSearched,
        selection: provider.currentSelection,
      ),
      builder: (context, state, child) {
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
                Icon(
                  state.hasSearched ? Icons.search_off : Icons.map,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  state.hasSearched ? '検索結果が見つかりません' : 'エリアを選択して検索してください',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.hasSearched) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '別のエリアで検索するか、\n検索範囲を広げてみてください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    '出張先や旅行先のエリアを\n選んで中華料理店を探そう',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            // エリア名を表示
            if (state.selection != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${state.selection!.displayName}の中華料理店',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.searchResults.length}件',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: state.searchResults.length,
                itemBuilder: (context, index) {
                  final store = state.searchResults[index];
                  return _buildStoreCard(store);
                },
              ),
            ),
            const ApiAttributionWidget(
              apiType: ApiAttributionType.hotpepper,
            ),
          ],
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

  Future<void> _addToWantToGo(Store store) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

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
      final storeWithStatus = store.copyWith(status: StoreStatus.wantToGo);
      await storeProvider.addStore(storeWithStatus);
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
}
