import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗詳細'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StoreHeaderWidget(store: widget.store),
            StoreInfoWidget(store: widget.store),
            StoreActionWidget(
              store: widget.store,
              onStatusChanged: (newStatus) =>
                  _updateStoreStatus(context, newStatus),
              onAddVisitRecord: () => _navigateToVisitRecordForm(context),
            ),
            // 地図を常時表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 250,
                child: WebViewMapWidget(
                  store: widget.store,
                  useOpenStreetMap: true,
                ),
              ),
            ),
            // 訪問記録セクション
            if (_isLoadingVisitRecords)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              VisitRecordsSectionWidget(
                storeId: widget.store.id,
                visitRecords: _visitRecords,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStoreStatus(
      BuildContext context, StoreStatus newStatus) async {
    if (widget.store.status == newStatus) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      await storeProvider.updateStoreStatus(widget.store.id, newStatus);

      // ステータス更新成功 - UI表示の変化で十分なためスナックバー削除
    } catch (e) {
      if (context.mounted) {
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

  void _navigateToVisitRecordForm(BuildContext context) async {
    // 訪問記録追加後に戻ってきたら、訪問記録を再読み込み
    await context.pushNamed('visit-record-form', extra: widget.store);
    // 画面に戻ってきた時に訪問記録を再読み込み
    _loadVisitRecords();
  }
}
