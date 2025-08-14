import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/entities/store.dart';

/// WebViewを使用した地図表示ウィジェット
class WebViewMapWidget extends StatefulWidget {
  final Store store;
  final bool useOpenStreetMap;

  const WebViewMapWidget({
    super.key,
    required this.store,
    this.useOpenStreetMap = false,
  });

  @override
  State<WebViewMapWidget> createState() => _WebViewMapWidgetState();
}

class _WebViewMapWidgetState extends State<WebViewMapWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      // WebViewの初期化
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
          ),
        );

      // 地図URLを読み込み
      final mapUrl = _buildMapUrl();
      _controller!.loadRequest(Uri.parse(mapUrl));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'WebView地図の初期化に失敗しました';
        });
      }
    }
  }

  /// Google Maps Embed APIのURLを構築
  String _buildMapUrl() {
    final lat = widget.store.lat;
    final lng = widget.store.lng;

    if (widget.useOpenStreetMap) {
      // OpenStreetMapの簡易HTML地図（APIキー不要）
      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 0; }
          #map { width: 100%; height: 100vh; }
        </style>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
      </head>
      <body>
        <div id="map"></div>
        <script>
          const map = L.map('map').setView([$lat, $lng], 15);
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
          }).addTo(map);
          L.marker([$lat, $lng]).addTo(map)
            .bindPopup('${widget.store.name}<br>${widget.store.address}')
            .openPopup();
        </script>
      </body>
      </html>
      ''';

      return 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
    } else {
      // APIキー不要のGoogle Maps iframe版
      return 'https://maps.google.com/maps?'
          'q=$lat,$lng&'
          'z=15&'
          'output=embed&'
          'language=ja';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            if (_controller != null)
              SizedBox(
                width:
                    constraints.maxWidth.isFinite ? constraints.maxWidth : 400,
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 400,
                child: WebViewWidget(controller: _controller!),
              ),
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('地図を読み込み中...'),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

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
            'WebView地図を表示できません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openExternalMapApp(),
            child: const Text('外部地図アプリで開く'),
          ),
        ],
      ),
    );
  }

  /// 外部地図アプリで開く
  Future<void> _openExternalMapApp() async {
    try {
      // StoreMapWidgetと同じ外部アプリ呼び出しロジック
      final navigationUrls = [
        'maps://maps.apple.com/?daddr=${widget.store.lat},${widget.store.lng}',
        'google.navigation:q=${widget.store.lat},${widget.store.lng}',
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${widget.store.lat},${widget.store.lng}')}',
      ];

      for (final urlString in navigationUrls) {
        Uri.parse(urlString);
        // url_launcherの使用
        // TODO: 実際の実装ではurl_launcherを使用
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WebViewMapWidget] External app launch error: $e');
      }
    }
  }
}
