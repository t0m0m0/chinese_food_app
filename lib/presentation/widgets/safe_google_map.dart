import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../main.dart';
import '../../core/debug/crash_handler.dart';

/// 안전한 Google Map 위젯 래퍼
///
/// Google Maps SDK의 네이티브 크래시를 방지하기 위해
/// 초기화 상태를 확인하고 안전하게 GoogleMap을 생성합니다
/// 注: 現在はWebViewMapWidgetの使用を推奨
class SafeGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;

  const SafeGoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.mapType = MapType.normal,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
    this.rotateGesturesEnabled = false,
    this.tiltGesturesEnabled = false,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.markers = const {},
    this.onMapCreated,
  });

  @override
  State<SafeGoogleMap> createState() => _SafeGoogleMapState();
}

class _SafeGoogleMapState extends State<SafeGoogleMap> {
  bool _isInitializing = false;
  bool _initializationFailed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ensureSafeInitialization();
  }

  /// Google Maps SDK의 안전한 초기화를 보장
  Future<void> _ensureSafeInitialization() async {
    CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_CREATION_ATTEMPT', details: {
      'widget_hash': hashCode,
      'initial_position':
          '${widget.initialCameraPosition.target.latitude},${widget.initialCameraPosition.target.longitude}',
      'marker_count': widget.markers.length,
    });

    if (GoogleMapsInitializer.isInitialized) {
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_ALREADY_INIT');
      return; // 이미 초기화됨
    }

    CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_INIT_START');

    setState(() {
      _isInitializing = true;
      _initializationFailed = false;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        debugPrint('[SafeGoogleMap] SDK 초기화 시작');
      }

      final success = await GoogleMapsInitializer.ensureInitialized();

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_INIT_COMPLETE', details: {
        'success': success,
        'widget_mounted': mounted,
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationFailed = !success;
          if (!success) {
            _errorMessage = 'Google Maps SDK 초기화에 실패했습니다';
          }
        });

        if (kDebugMode) {
          debugPrint('[SafeGoogleMap] SDK 초기化 ${success ? '성공' : '실패'}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SafeGoogleMap] SDK 초기化 오류: $e');
      }

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_INIT_EXCEPTION',
          details: {
            'error': e.toString(),
            'error_type': e.runtimeType.toString(),
            'widget_mounted': mounted,
          },
          stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationFailed = true;
          _errorMessage = 'Google Maps 초기化 중 오류가 발생했습니다';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_BUILD_START', details: {
      'widget_hash': hashCode,
      'is_initializing': _isInitializing,
      'initialization_failed': _initializationFailed,
      'context_mounted': context.mounted,
    });

    try {
      // 初期化 중인 경우
      if (_isInitializing) {
        CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_SHOWING_LOADING');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('지도를 준비하고 있습니다...'),
            ],
          ),
        );
      }

      // 初期화 실패한 경우
      if (_initializationFailed) {
        CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_SHOWING_ERROR');
        return _buildErrorWidget();
      }

      // 안전하게 GoogleMap 위젯 생성
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_BUILD_CALLING_SAFE_MAP');
      final result = _buildSafeGoogleMap();

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_BUILD_SUCCESS');
      return result;
    } catch (e, stackTrace) {
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_BUILD_FAILED',
          details: {
            'error': e.toString(),
            'error_type': e.runtimeType.toString(),
            'widget_hash': hashCode,
          },
          stackTrace: stackTrace);

      // Build error時はエラー위젯 표시
      return _buildErrorWidget();
    }
  }

  /// 오류 표시 위젯
  Widget _buildErrorWidget() {
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
            _errorMessage ?? '지도를 표시할 수 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryInitialization,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 安全なGoogleMap ウィジェット生成
  Widget _buildSafeGoogleMap() {
    try {
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_CREATING_GOOGLEMAP',
          details: {
            'camera_target':
                '${widget.initialCameraPosition.target.latitude},${widget.initialCameraPosition.target.longitude}',
            'camera_zoom': widget.initialCameraPosition.zoom,
            'marker_count': widget.markers.length,
          });

      // ステップ1: CameraPosition の詳細ログ
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_CAMERA_POSITION_DETAILS',
          details: {
            'camera_bearing': widget.initialCameraPosition.bearing,
            'camera_tilt': widget.initialCameraPosition.tilt,
            'target_latitude': widget.initialCameraPosition.target.latitude,
            'target_longitude': widget.initialCameraPosition.target.longitude,
          });

      // ステップ2: Markers の詳細ログ
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_MARKERS_DETAILS', details: {
        'markers_count': widget.markers.length,
        'markers_info': widget.markers
            .map((m) => {
                  'markerId': m.markerId.value,
                  'position': '${m.position.latitude},${m.position.longitude}',
                  'infoWindow_title': m.infoWindow.title ?? 'null',
                })
            .toList(),
      });

      // ステップ3: GoogleMap プロパティの個別ログ
      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_MAP_PROPERTIES', details: {
        'mapType': widget.mapType.toString(),
        'myLocationEnabled': widget.myLocationEnabled,
        'myLocationButtonEnabled': widget.myLocationButtonEnabled,
        'zoomControlsEnabled': widget.zoomControlsEnabled,
        'compassEnabled': widget.compassEnabled,
        'rotateGesturesEnabled': widget.rotateGesturesEnabled,
        'tiltGesturesEnabled': widget.tiltGesturesEnabled,
        'scrollGesturesEnabled': widget.scrollGesturesEnabled,
        'zoomGesturesEnabled': widget.zoomGesturesEnabled,
      });

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_ABOUT_TO_CREATE_GOOGLEMAP');

      final googleMap = GoogleMap(
        initialCameraPosition: widget.initialCameraPosition,
        mapType: widget.mapType,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationButtonEnabled,
        zoomControlsEnabled: widget.zoomControlsEnabled,
        compassEnabled: widget.compassEnabled,
        rotateGesturesEnabled: widget.rotateGesturesEnabled,
        tiltGesturesEnabled: widget.tiltGesturesEnabled,
        scrollGesturesEnabled: widget.scrollGesturesEnabled,
        zoomGesturesEnabled: widget.zoomGesturesEnabled,
        markers: widget.markers,
        onMapCreated: (GoogleMapController controller) {
          try {
            CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_MAP_CREATED_START',
                details: {
                  'controller_hash': controller.hashCode,
                });

            widget.onMapCreated?.call(controller);

            CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_MAP_CREATED_SUCCESS');
          } catch (e, stackTrace) {
            CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_MAP_CREATED_FAILED',
                details: {
                  'error': e.toString(),
                  'error_type': e.runtimeType.toString(),
                },
                stackTrace: stackTrace);
          }
        },
      );

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_GOOGLEMAP_CREATED_SUCCESS');
      return googleMap;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SafeGoogleMap] GoogleMap ウィジェット生成失敗: $e');
      }

      CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_GOOGLEMAP_CREATION_FAILED',
          details: {
            'error': e.toString(),
            'error_type': e.runtimeType.toString(),
          },
          stackTrace: stackTrace);

      // GoogleMap ウィジェット生成失敗時は오류 위젯 표시
      return _buildErrorWidget();
    }
  }

  /// 초기화 재시도
  void _retryInitialization() {
    CrashHandler.logGoogleMapsEvent('SAFE_WIDGET_RETRY_INIT');
    _ensureSafeInitialization();
  }
}
