import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/duplicate_store_checker.dart';
import '../../../core/utils/store_utils.dart';
import '../../../core/constants/area_data.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/area.dart';
import '../../providers/store_provider.dart';
import '../../providers/area_search_provider.dart';
import '../../widgets/cached_store_image.dart';
import '../../widgets/common_states.dart';
import '../../widgets/api_attribution_widget.dart';
import '../store_detail/store_detail_page.dart';

/// エリア探索ページ（昭和レトロモダン）
///
/// 都道府県・市区町村の階層選択によるエリア指定検索を提供
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late AreaSearchProvider _areaSearchProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    _areaSearchProvider = AreaSearchProvider(storeProvider: storeProvider);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _areaSearchProvider.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _areaSearchProvider.loadMoreResults();
    }
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
              DecorativeElements.lanternIcon(size: 28),
              const SizedBox(width: 10),
              Text(
                'エリア',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              DecorativeElements.ramenBowl(size: 28),
            ],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primaryRed),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: DecorativeElements.norenDecoration(
              height: 3,
              color: AppTheme.primaryRed,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildAreaSelector(),
            DecorativeElements.retroDivider(
              color: AppTheme.accentBeige,
              indent: 16,
            ),
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
        Text(
          '都道府県を選択',
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showPrefectureBottomSheet(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentCream,
              border: Border.all(color: AppTheme.accentBeige, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedPrefecture?.name ?? '選択してください',
                  style: AppTheme.bodyLarge.copyWith(
                    color: selectedPrefecture != null
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  color: selectedPrefecture != null
                      ? AppTheme.primaryRed
                      : AppTheme.textTertiary,
                ),
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
        Text(
          '市区町村を選択（任意）',
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCityBottomSheet(prefecture),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentCream,
              border: Border.all(color: AppTheme.accentBeige, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCity?.name ?? '全域',
                  style: AppTheme.bodyLarge.copyWith(
                    color: selectedCity != null
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
                ),
                Row(
                  children: [
                    if (selectedCity != null)
                      GestureDetector(
                        onTap: () => _areaSearchProvider.clearCity(),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.textTertiary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: AppTheme.textSecondary),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.expand_more_rounded,
                      color: selectedCity != null
                          ? AppTheme.primaryRed
                          : AppTheme.textTertiary,
                    ),
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

    return DecorativeElements.retroBadge(
      text: '${selection.displayName}の中華料理店',
      backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
      textColor: AppTheme.primaryRed,
      fontSize: 12,
    );
  }

  void _showPrefectureBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '都道府県を選択',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            DecorativeElements.retroDivider(
              color: AppTheme.accentBeige,
              indent: 20,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: AreaData.prefecturesByRegion.length,
                itemBuilder: (context, index) {
                  final region =
                      AreaData.prefecturesByRegion.keys.elementAt(index);
                  final prefectures = AreaData.prefecturesByRegion[region]!;

                  return ExpansionTile(
                    title: Text(
                      region,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    initiallyExpanded: region == '関東',
                    iconColor: AppTheme.primaryRed,
                    collapsedIconColor: AppTheme.textTertiary,
                    children: prefectures.map((prefecture) {
                      return ListTile(
                        title: Text(
                          prefecture.name,
                          style: AppTheme.bodyLarge,
                        ),
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 32),
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
          ],
        ),
      ),
    );
  }

  void _showCityBottomSheet(Prefecture prefecture) {
    final cities = AreaData.getCitiesForPrefecture(prefecture.code);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '${prefecture.name}の市区町村',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            DecorativeElements.retroDivider(
              color: AppTheme.accentBeige,
              indent: 20,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    title: Text('全域', style: AppTheme.bodyLarge),
                    leading:
                        const Icon(Icons.public, color: AppTheme.primaryRed),
                    dense: true,
                    onTap: () {
                      _areaSearchProvider.clearCity();
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(color: AppTheme.accentBeige),
                  ...cities.map((city) => ListTile(
                        title: Text(city.name, style: AppTheme.bodyLarge),
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        onTap: () {
                          _areaSearchProvider.selectCity(city);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
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
          return const AppLoadingState(message: '検索中...');
        }

        if (state.errorMessage != null) {
          return AppErrorState(message: state.errorMessage);
        }

        if (state.searchResults.isEmpty) {
          return AppEmptyState(
            message: state.hasSearched ? '検索結果が見つかりません' : 'エリアを選択して検索してください',
            subMessage: state.hasSearched
                ? '別のエリアで検索するか、\n検索範囲を広げてみてください'
                : '出張先や旅行先のエリアを\n選んで中華料理店を探そう',
            icon: state.hasSearched
                ? DecorativeElements.gyozaIcon(size: 64)
                : DecorativeElements.ramenBowl(size: 64),
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
                    const Icon(Icons.restaurant,
                        size: 18, color: AppTheme.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      '${state.selection!.displayName}の中華料理店',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            Expanded(
              child: Selector<AreaSearchProvider,
                  ({bool isLoadingMore, bool hasMoreResults})>(
                selector: (context, provider) => (
                  isLoadingMore: provider.isLoadingMore,
                  hasMoreResults: provider.hasMoreResults,
                ),
                builder: (context, paginationState, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: state.searchResults.length +
                        (paginationState.hasMoreResults ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < state.searchResults.length) {
                        final store = state.searchResults[index];
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('search_${store.id}_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                              milliseconds: 300 + (index.clamp(0, 10) * 50)),
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
                          child: _buildStoreCard(store),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: paginationState.isLoadingMore
                                ? const CircularProgressIndicator(
                                    color: AppTheme.primaryRed,
                                    strokeWidth: 3,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                    },
                  );
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 店舗画像（大きめ、角丸）
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedStoreImage(
                    imageUrl: store.imageUrl,
                    width: 72,
                    height: 72,
                    borderRadius: 10,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 店舗情報
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
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            store.address,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (store.memo?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        store.memo!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryRed,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ステータスアイコン
              Selector<StoreProvider, List<Store>>(
                selector: (context, provider) => provider.stores,
                builder: (context, stores, child) {
                  final existingStore = stores
                      .where((s) =>
                          s.name == store.name && s.address == store.address)
                      .firstOrNull;

                  if (existingStore != null) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: StoreUtils.getStatusColor(existingStore.status)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        StoreUtils.getStatusIcon(existingStore.status),
                        color: StoreUtils.getStatusColor(existingStore.status),
                        size: 20,
                      ),
                    );
                  }

                  return IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppTheme.textTertiary,
                    ),
                    onPressed: () => _addToWantToGo(store),
                  );
                },
              ),
            ],
          ),
        ),
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
            backgroundColor: AppTheme.warningOrange,
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
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
