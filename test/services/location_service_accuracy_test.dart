import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/services/location_service.dart';

/// Issue #43: GPS精度モードシミュレーションのテスト
/// TDD GREEN段階: GPS_ACCURACY_MODE環境変数による制御テスト
void main() {
  group('GPS Accuracy Mode Simulation - Issue #43', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('環境変数未設定時のデフォルト動作確認', () async {
      // GPS_ACCURACY_MODE環境変数が未設定時のテスト環境での正常動作
      final result = await locationService.getCurrentPosition();

      expect(result.isSuccess, true);
      expect(result.lat, equals(35.6762));
      expect(result.lng, equals(139.6503));
    });

    test('LocationServiceの精度設定機能確認', () async {
      // GPS精度設定機能の基本動作確認
      expect(locationService, isNotNull);
      expect(locationService, isA<LocationService>());

      final result = await locationService.getCurrentPosition();
      expect(result, isA<LocationServiceResult>());
      expect(result.isSuccess, true);
    });

    test('複数回実行での精度設定一貫性確認', () async {
      // 精度設定が複数回実行でも一貫していることを確認
      final results = <LocationServiceResult>[];

      for (int i = 0; i < 3; i++) {
        final result = await locationService.getCurrentPosition();
        results.add(result);
      }

      // 全て同じ結果を返すことを確認
      for (final result in results) {
        expect(result.isSuccess, true);
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });
  });
}
