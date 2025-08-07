import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

/// StoreMapWidget用の定数
class _StoreMapConstants {
  static const double defaultZoom = 15.0;
  static const double fabPosition = 16.0;
}

class StoreMapWidget extends StatelessWidget {
  final Store store;

  const StoreMapWidget({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(store.lat, store.lng),
            zoom: _StoreMapConstants.defaultZoom,
          ),
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: true,
          rotateGesturesEnabled: false, // 回転無効でUX向上
          tiltGesturesEnabled: false, // 傾き無効でUX向上
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          markers: {
            Marker(
              markerId: MarkerId(store.id),
              position: LatLng(store.lat, store.lng),
              infoWindow: InfoWindow(
                title: store.name,
                snippet: store.address,
              ),
            ),
          },
        ),
        Positioned(
          top: _StoreMapConstants.fabPosition,
          right: _StoreMapConstants.fabPosition,
          child: FloatingActionButton(
            mini: true,
            tooltip: '外部地図アプリで開く',
            onPressed: () => _openExternalNavigation(),
            child: Semantics(
              label: '外部地図アプリでナビゲーションを開始',
              child: const Icon(Icons.navigation),
            ),
          ),
        ),
      ],
    );
  }

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
            'StoreMapWidget: All navigation URLs failed for store: ${store.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StoreMapWidget navigation error: $e');
      }
      // 本番環境ではサイレントフェール
    }
  }
}
