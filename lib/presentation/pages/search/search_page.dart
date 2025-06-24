import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isLocationSearch = true; // true: 現在地検索, false: 住所検索
  bool _isLoading = false;
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 検索タイプ切り替え
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('現在地で検索'),
                        icon: Icon(Icons.my_location),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('住所で検索'),
                        icon: Icon(Icons.location_on),
                      ),
                    ],
                    selected: {_isLocationSearch},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isLocationSearch = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 検索フォーム
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (!_isLocationSearch)
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '住所を入力',
                      hintText: '例: 東京都渋谷区',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performSearch,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('検索'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 検索結果エリア
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '検索結果', icon: Icon(Icons.list)),
                      Tab(text: 'マップ', icon: Icon(Icons.map)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 検索結果リスト
                        _buildSearchResults(),
                        // Google Maps
                        _buildMapView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // TODO: 実際の検索結果データを表示
    return const Center(
      child: Text(
        '検索結果',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildMapView() {
    // TODO: Google Maps APIキーの設定が必要
    return const GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(35.6762, 139.6503), // 東京駅
        zoom: 11.0,
      ),
    );
  }

  void _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 実際の検索処理を実装
      await Future.delayed(const Duration(seconds: 1)); // 模擬的な遅延
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('検索が完了しました'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('検索エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}