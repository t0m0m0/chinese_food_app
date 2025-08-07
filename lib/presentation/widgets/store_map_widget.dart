import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

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
            zoom: 15.0,
          ),
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
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            tooltip: '外部地図アプリで開く',
            onPressed: () => _openExternalNavigation(),
            child: const Icon(Icons.navigation),
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalNavigation() async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${store.lat},${store.lng}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // URL起動に失敗した場合は何もしない（サイレントフェール）
      }
    } catch (e) {
      // エラーが発生した場合はサイレントフェール
    }
  }
}
