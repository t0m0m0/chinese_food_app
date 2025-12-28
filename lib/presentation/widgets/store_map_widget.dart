import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'webview_map_widget.dart';

/// 地図表示ウィジェット（WebView版）
/// Google Maps SDKクラッシュ問題を解決するためWebView実装を採用
class StoreMapWidget extends StatelessWidget {
  final Store store;

  const StoreMapWidget({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // OpenStreetMap WebView地図
        Expanded(
          child: Stack(
            children: [
              WebViewMapWidget(
                store: store,
                useOpenStreetMap: true,
              ),
              // 外部地図アプリでナビゲーション開始ボタン（右上）
              Positioned(
                top: 16.0,
                right: 16.0,
                child: FloatingActionButton(
                  mini: true,
                  tooltip: 'ナビを開始',
                  onPressed: () => _openExternalNavigation(),
                  child: Semantics(
                    label: '外部地図アプリでナビゲーションを開始',
                    child: const Icon(Icons.navigation),
                  ),
                ),
              ),
            ],
          ),
        ),
        // マップアプリで開くボタン（地図の下）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          child: OutlinedButton.icon(
            onPressed: () => _openInMapApp(),
            icon: const Icon(Icons.map),
            label: const Text('マップアプリで開く'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
        ),
      ],
    );
  }

  /// 外部マップアプリで店舗位置を表示（ナビゲーションではなく位置表示）
  Future<void> _openInMapApp() async {
    try {
      // 店舗名をURLエンコード
      final encodedName = Uri.encodeComponent(store.name);

      // プラットフォーム別URL優先順位（位置表示用）
      final mapUrls = [
        // iOS: Apple Maps（位置表示）
        'maps://maps.apple.com/?ll=${store.lat},${store.lng}&q=$encodedName',
        // Google Maps app（iOS/Android）
        'comgooglemaps://?q=${store.lat},${store.lng}',
        // Universal fallback: Web URL
        'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}',
      ];

      for (final urlString in mapUrls) {
        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return; // 成功時は処理終了
        }
      }

      // 全てのURLが失敗した場合
      if (kDebugMode) {
        debugPrint(
            '[StoreMapWidget] All map URLs failed for store: ${store.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StoreMapWidget] Open map app error: $e');
      }
      // 本番環境ではサイレントフェール
    }
  }

  /// 外部地図アプリでナビゲーションを開始
  Future<void> _openExternalNavigation() async {
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
            '[StoreMapWidget] All navigation URLs failed for store: ${store.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StoreMapWidget] Navigation error: $e');
      }
      // 本番環境ではサイレントフェール
    }
  }
}
