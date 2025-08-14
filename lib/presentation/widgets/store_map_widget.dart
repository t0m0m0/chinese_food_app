import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/core/utils/map_utils.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import '../../main.dart';
import 'safe_google_map.dart';
import 'webview_map_widget.dart';
import '../../core/debug/crash_handler.dart';

/// StoreMapWidget用の定数
class _StoreMapConstants {
  static const double defaultZoom = 15.0;
  static const double fabPosition = 16.0;
}

class StoreMapWidget extends StatelessWidget {
  final Store store;
  final bool useWebView;

  const StoreMapWidget({
    super.key,
    required this.store,
    this.useWebView = false, // デフォルトはネイティブGoogleMap
  });

  @override
  Widget build(BuildContext context) {
    // WebView版を使用する場合
    if (useWebView) {
      return WebViewMapWidget(store: store);
    }

    // ネイティブGoogleMap版を使用する場合
    return FutureBuilder<bool>(
      future: _checkGoogleMapsAvailability(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return _buildErrorWidget(context);
        }

        return _buildGoogleMap();
      },
    );
  }

  /// Google Maps表示エラー時のウィジェット
  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '地図を表示できません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _openExternalNavigation(),
            child: const Text('外部地図アプリで開く'),
          ),
        ],
      ),
    );
  }

  /// Google Mapウィジェット
  Widget _buildGoogleMap() {
    return Stack(
      children: [
        SafeGoogleMap(
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

  /// Google Mapsの利用可能性をチェック
  Future<bool> _checkGoogleMapsAvailability() async {
    CrashHandler.logGoogleMapsEvent('WIDGET_AVAILABILITY_CHECK_START',
        details: {
          'store_id': store.id,
          'store_name': store.name,
          'coordinates': '${store.lat},${store.lng}',
        });

    try {
      // 座標値の検証
      final coordsValid = MapUtils.isValidCoordinate(store.lat, store.lng);
      CrashHandler.logGoogleMapsEvent('COORDINATE_VALIDATION', details: {
        'lat': store.lat,
        'lng': store.lng,
        'valid': coordsValid,
      });

      if (!coordsValid) {
        if (kDebugMode) {
          debugPrint(
            '[StoreMapWidget] Invalid coordinates - '
            'lat: ${store.lat}, lng: ${store.lng}',
          );
        }
        CrashHandler.logGoogleMapsEvent('AVAILABILITY_FAIL_COORDINATES');
        return false;
      }

      // Google Maps SDKの初期化状態をチェック
      final sdkInitialized = GoogleMapsInitializer.isInitialized;
      CrashHandler.logGoogleMapsEvent('SDK_STATUS_CHECK', details: {
        'sdk_initialized': sdkInitialized,
      });

      if (!sdkInitialized) {
        if (kDebugMode) {
          debugPrint(
              '[StoreMapWidget] Google Maps SDK not initialized - attempting initialization');
        }

        CrashHandler.logGoogleMapsEvent('WIDGET_ATTEMPTING_SDK_INIT');

        // SDK初期化を試行
        final initializationSuccess =
            await GoogleMapsInitializer.ensureInitialized();
        CrashHandler.logGoogleMapsEvent('WIDGET_SDK_INIT_RESULT', details: {
          'success': initializationSuccess,
        });

        if (!initializationSuccess) {
          if (kDebugMode) {
            debugPrint(
                '[StoreMapWidget] Google Maps SDK initialization failed');
          }
          CrashHandler.logGoogleMapsEvent('AVAILABILITY_FAIL_SDK_INIT');
          return false;
        }
      }

      // ConfigManagerの初期化状態を安全にチェック
      final configInitialized = ConfigManager.isInitialized;
      CrashHandler.logGoogleMapsEvent('CONFIG_STATUS_CHECK', details: {
        'config_initialized': configInitialized,
      });

      if (!configInitialized) {
        if (kDebugMode) {
          debugPrint('[StoreMapWidget] ConfigManager not initialized');
        }
        CrashHandler.logGoogleMapsEvent('AVAILABILITY_FAIL_CONFIG');
        return false;
      }

      // APIキーの検証
      final apiKey = ConfigManager.googleMapsApiKey;
      final apiKeyValid = MapUtils.isValidGoogleMapsApiKey(apiKey);
      CrashHandler.logGoogleMapsEvent('API_KEY_VALIDATION', details: {
        'api_key_valid': apiKeyValid,
        'api_key_length': apiKey.length,
        'api_key_starts_with':
            apiKey.isNotEmpty ? apiKey.substring(0, 6) : 'empty',
      });

      if (!apiKeyValid) {
        if (kDebugMode) {
          debugPrint('[StoreMapWidget] Invalid Google Maps API key');
        }
        CrashHandler.logGoogleMapsEvent('AVAILABILITY_FAIL_API_KEY');
        return false;
      }

      CrashHandler.logGoogleMapsEvent('AVAILABILITY_CHECK_SUCCESS');
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[StoreMapWidget] Availability check failed: $e');
      }

      CrashHandler.logGoogleMapsEvent('AVAILABILITY_CHECK_EXCEPTION',
          details: {
            'error': e.toString(),
            'error_type': e.runtimeType.toString(),
            'store_id': store.id,
          },
          stackTrace: stackTrace);

      return false;
    }
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
