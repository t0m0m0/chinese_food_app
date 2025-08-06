import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../providers/store_provider.dart';
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
              onShowMap: () => _showMapNotImplemented(context),
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
        final statusText = _getStatusText(newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータスを「$statusText」に更新しました'),
            backgroundColor:
                _getStatusColor(newStatus, Theme.of(context).colorScheme),
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

  void _showMapNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('地図表示機能は実装予定です')),
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

  String _getStatusText(StoreStatus? status) {
    switch (status) {
      case StoreStatus.wantToGo:
        return '行きたい';
      case StoreStatus.visited:
        return '行った';
      case StoreStatus.bad:
        return '興味なし';
      default:
        return '未設定';
    }
  }
}

