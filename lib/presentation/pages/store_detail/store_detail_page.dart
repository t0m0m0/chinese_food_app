import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    try {
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StoreDetailPage: Map dialog display error: $e');
      }

      // エラー時はフォールバックダイアログを表示
      _showMapErrorDialog(context);
    }
  }

  /// 地図表示エラー時のフォールバックダイアログ
  void _showMapErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('地図表示エラー'),
        content: const Text(
          '地図を表示できませんでした。\n外部地図アプリで表示しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openExternalMapApp(context);
            },
            child: const Text('外部アプリで開く'),
          ),
        ],
      ),
    );
  }

  /// 外部地図アプリで開く
  Future<void> _openExternalMapApp(BuildContext context) async {
    try {
      // プラットフォーム別URL優先順位
      final navigationUrls = [
        // iOS: Apple Maps (ネイティブアプリ)
        'maps://maps.apple.com/?daddr=${store.lat},${store.lng}',
        // Android: Google Maps app
        'google.navigation:q=${store.lat},${store.lng}',
        // Universal fallback: Web URL
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${store.lat},${store.lng}')}',
      ];

      for (final urlString in navigationUrls) {
        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return; // 成功時は処理終了
        }
      }

      // 全てのURLが失敗した場合
      if (kDebugMode) {
        debugPrint(
          'StoreDetailPage: All navigation URLs failed for store: ${store.name}',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('外部地図アプリを開けませんでした'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StoreDetailPage: External map app launch error: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('外部地図アプリを開けませんでした'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
