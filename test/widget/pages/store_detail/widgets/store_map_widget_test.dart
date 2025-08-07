import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/widgets/store_map_widget.dart';

void main() {
  group('StoreMapWidget', () {
    late Store testStore;

    setUp(() {
      testStore = Store(
        id: 'test-store-id',
        name: 'テスト中華店',
        address: '東京都新宿区歌舞伎町1-1-1',
        lat: 35.6938,
        lng: 139.7034,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('should display GoogleMap widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should display marker at store location',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final googleMapFinder = find.byType(GoogleMap);
      expect(googleMapFinder, findsOneWidget);

      final GoogleMap googleMap = tester.widget(googleMapFinder);
      expect(googleMap.markers.length, 1);
      expect(googleMap.markers.first.position.latitude, testStore.lat);
      expect(googleMap.markers.first.position.longitude, testStore.lng);
    });

    testWidgets('should display info window with store information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final googleMapFinder = find.byType(GoogleMap);
      final GoogleMap googleMap = tester.widget(googleMapFinder);
      final marker = googleMap.markers.first;

      expect(marker.infoWindow.title, testStore.name);
      expect(marker.infoWindow.snippet, testStore.address);
    });

    testWidgets('should center map on store location',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final googleMapFinder = find.byType(GoogleMap);
      final GoogleMap googleMap = tester.widget(googleMapFinder);

      expect(googleMap.initialCameraPosition.target.latitude, testStore.lat);
      expect(googleMap.initialCameraPosition.target.longitude, testStore.lng);
      expect(googleMap.initialCameraPosition.zoom, 15.0);
    });

    testWidgets('should show external navigation button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('should handle external navigation button tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final navigationButton = find.byIcon(Icons.navigation);
      expect(navigationButton, findsOneWidget);

      await tester.tap(navigationButton);
      await tester.pumpAndSettle();
    });

    testWidgets('should have proper accessibility labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final navigationButton = find.byType(FloatingActionButton);
      expect(navigationButton, findsOneWidget);

      final FloatingActionButton button = tester.widget(navigationButton);
      expect(button.tooltip, '外部地図アプリで開く');
    });

    testWidgets('should display GoogleMap with proper semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // GoogleMapが表示されていることを確認
      expect(find.byType(GoogleMap), findsOneWidget);

      // ナビゲーションボタンにセマンティクス情報が含まれていることを確認
      expect(find.byTooltip('外部地図アプリで開く'), findsOneWidget);
    });

    testWidgets('should have enhanced accessibility with Semantics widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 特定のセマンティクスラベルが設定されていることを確認
      final semanticsFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label == '外部地図アプリでナビゲーションを開始');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('should have proper Google Maps configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMapWidget(store: testStore),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final googleMapFinder = find.byType(GoogleMap);
      expect(googleMapFinder, findsOneWidget);

      final GoogleMap googleMap = tester.widget(googleMapFinder);
      expect(googleMap.mapType, MapType.normal);
      expect(googleMap.myLocationEnabled, false);
      expect(googleMap.myLocationButtonEnabled, false);
      expect(googleMap.zoomControlsEnabled, true);
      expect(googleMap.compassEnabled, true);
      expect(googleMap.rotateGesturesEnabled, false);
      expect(googleMap.tiltGesturesEnabled, false);
      expect(googleMap.scrollGesturesEnabled, true);
      expect(googleMap.zoomGesturesEnabled, true);
    });
  });
}
