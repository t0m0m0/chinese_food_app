import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/store_utils.dart';
import '../../../domain/entities/store.dart';
import '../../providers/store_provider.dart';
import '../../widgets/store_map_widget.dart';
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
              onShowMap: () => _showMap(context),
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

      if (context.mounted) {
        final statusText = StoreUtils.getStatusText(newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータスを「$statusText」に更新しました'),
            backgroundColor: StoreUtils.getStatusColor(
                newStatus, Theme.of(context).colorScheme),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  void _showMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: 400.0, // 明示的にdouble型
          width: double.maxFinite,
          child: Column(
            children: [
              AppBar(
                title: Text(store.name),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: StoreMapWidget(store: store),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
