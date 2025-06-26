import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chinese_food_app/services/maps/map_service.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('MapService Tests', () {
    final testStores = [
      Store(
        id: 'store-1',
        name: '中華料理 龍華楼',
        address: '東京都新宿区西新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2025, 6, 26),
      ),
      Store(
        id: 'store-2',
        name: '中華料理 福来',
        address: '東京都新宿区西新宿2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.visited,
        createdAt: DateTime(2025, 6, 26),
      ),
      Store(
        id: 'store-3',
        name: '中華料理 悪いお店',
        address: '東京都新宿区西新宿3-3-3',
        lat: 35.6875,
        lng: 139.6900,
        status: StoreStatus.bad,
        createdAt: DateTime(2025, 6, 26),
      ),
    ];

    test('should create markers from stores', () {
      final markers = MapService.createMarkersFromStores(testStores);

      expect(markers.length, 3);

      final markerIds = markers.map((m) => m.markerId.value).toList();
      expect(markerIds, contains('store-1'));
      expect(markerIds, contains('store-2'));
      expect(markerIds, contains('store-3'));
    });

    test('should create markers with correct positions', () {
      final markers = MapService.createMarkersFromStores(testStores);

      final store1Marker =
          markers.firstWhere((m) => m.markerId.value == 'store-1');

      expect(store1Marker.position.latitude, 35.6917);
      expect(store1Marker.position.longitude, 139.7006);
    });

    test('should create markers with correct info windows', () {
      final markers = MapService.createMarkersFromStores(testStores);

      final store1Marker =
          markers.firstWhere((m) => m.markerId.value == 'store-1');

      expect(store1Marker.infoWindow.title, '中華料理 龍華楼');
      expect(store1Marker.infoWindow.snippet, '東京都新宿区西新宿1-1-1');
    });

    test('should create empty marker set for empty stores', () {
      final markers = MapService.createMarkersFromStores([]);
      expect(markers.isEmpty, true);
    });

    test('should calculate bounds for multiple stores', () {
      final bounds = MapService.calculateBounds(testStores);

      expect(bounds, isNotNull);
      expect(bounds!.southwest.latitude, 35.6875); // minimum lat
      expect(bounds.southwest.longitude, 139.6900); // minimum lng
      expect(bounds.northeast.latitude, 35.6917); // maximum lat
      expect(bounds.northeast.longitude, 139.7006); // maximum lng
    });

    test('should return null bounds for empty stores', () {
      final bounds = MapService.calculateBounds([]);
      expect(bounds, isNull);
    });

    test('should calculate bounds for single store', () {
      final singleStore = [testStores.first];
      final bounds = MapService.calculateBounds(singleStore);

      expect(bounds, isNotNull);
      expect(bounds!.southwest.latitude, 35.6917);
      expect(bounds.southwest.longitude, 139.7006);
      expect(bounds.northeast.latitude, 35.6917);
      expect(bounds.northeast.longitude, 139.7006);
    });

    test('should have correct default values', () {
      expect(MapService.defaultMapType, MapType.normal);
      expect(MapService.defaultZoom, 15.0);

      // 東京駅の座標をチェック
      expect(MapService.defaultCameraPosition.target.latitude, 35.6812);
      expect(MapService.defaultCameraPosition.target.longitude, 139.7671);
      expect(MapService.defaultCameraPosition.zoom, 15.0);
    });
  });
}
