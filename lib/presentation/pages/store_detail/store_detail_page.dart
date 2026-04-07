import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../widgets/common_states.dart';
import '../../../core/di/di_container_interface.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/visit_record.dart';
import '../../../domain/usecases/get_visit_records_by_store_id_usecase.dart';
import '../../providers/store_provider.dart';
import '../../widgets/webview_map_widget.dart';
import 'widgets/store_header_widget.dart';
import 'widgets/store_info_widget.dart';
import 'widgets/store_action_widget.dart';
import 'widgets/visit_records_section_widget.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({
    super.key,
    required this.store,
  });

  final Store store;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late GetVisitRecordsByStoreIdUsecase _getVisitRecordsUsecase;
  List<VisitRecord> _visitRecords = [];
  bool _isLoadingVisitRecords = true;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Provider経由で設定済みのDIContainerを取得
      final container =
          Provider.of<DIContainerInterface>(context, listen: false);
      _getVisitRecordsUsecase = container.getGetVisitRecordsByStoreIdUsecase();
      _loadVisitRecords();
      _isInitialized = true;
    }
  }

  Future<void> _loadVisitRecords() async {
    try {
      final records = await _getVisitRecordsUsecase.call(widget.store.id);
      if (mounted) {
        setState(() {
          _visitRecords = records;
          _isLoadingVisitRecords = false;
        });
      }
    } catch (e) {
      developer.log(
        'Failed to load visit records for store ${widget.store.id}',
        name: 'StoreDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoadingVisitRecords = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);

    // StoreProviderから最新の店舗情報を取得
    // ステータス変更時にUIを即座に更新するため
    final currentStore = storeProvider.stores
        .firstWhere((s) => s.id == widget.store.id, orElse: () => widget.store);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecorativeElements.ramenBowl(size: 28),
            const SizedBox(width: 10),
            Text(
              '店舗詳細',
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
          preferredSize: const Size.fromHeight(3),
          child: DecorativeElements.norenDecoration(
            height: 3,
            color: AppTheme.primaryRed,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StoreHeaderWidget(store: currentStore),
            StoreInfoWidget(store: currentStore),
            StoreActionWidget(
              store: currentStore,
              onStatusChanged: (newStatus) =>
                  _updateStoreStatus(context, currentStore, newStatus),
              onAddVisitRecord: () => _navigateToVisitRecordForm(context),
            ),
            // 地図を常時表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 250,
                child: WebViewMapWidget(
                  store: currentStore,
                  useOpenStreetMap: true,
                ),
              ),
            ),
            // 訪問記録セクション
            if (_isLoadingVisitRecords)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: AppLoadingState(),
              )
            else
              VisitRecordsSectionWidget(
                storeId: currentStore.id,
                visitRecords: _visitRecords,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStoreStatus(
      BuildContext context, Store currentStore, StoreStatus newStatus) async {
    if (currentStore.status == newStatus) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      await storeProvider.updateStoreStatus(currentStore.id, newStatus);

      // ステータス更新成功 - UI表示の変化で十分なためスナックバー削除
    } catch (e) {
      if (context.mounted) {
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

  void _navigateToVisitRecordForm(BuildContext context) async {
    // Providerを非同期処理前に取得
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // 訪問記録追加後に戻ってきたら、訪問記録を再読み込み
    await context.pushNamed('visit-record-form', extra: widget.store);

    // 画面に戻ってきた時に訪問記録とStoreProviderの店舗リストを再読み込み
    // これにより、訪問記録追加時の自動ステータス変更がUIに即座に反映される
    if (mounted) {
      await storeProvider.loadStores();
      _loadVisitRecords();
    }
  }
}
