import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../providers/store_provider.dart';
import '../../widgets/webview_map_widget.dart';
import 'widgets/store_header_widget.dart';
import 'widgets/store_info_widget.dart';
import 'widgets/store_action_widget.dart';

class StoreDetailPage extends StatelessWidget {
  const StoreDetailPage({
    super.key,
    required this.store,
  });

  final Store store;

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
            StoreHeaderWidget(store: store),
            StoreInfoWidget(store: store),
            StoreActionWidget(
              store: store,
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
                  store: store,
                  useOpenStreetMap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStoreStatus(
      BuildContext context, StoreStatus newStatus) async {
    if (store.status == newStatus) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      await storeProvider.updateStoreStatus(store.id, newStatus);

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

  void _navigateToVisitRecordForm(BuildContext context) {
    context.pushNamed('visit-record-form', extra: store);
  }
}
