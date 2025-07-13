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

    test('GPS_ACCURACY_MODE=low で低精度エラーが発生すること', () async {
      // 環境変数 GPS_ACCURACY_MODE=low で実行されることを前提
      final result = await locationService.getCurrentPosition();

      expect(result.isSuccess, false);
      expect(result.error, contains('GPS精度が低すぎます'));
    });

    test('GPS_ACCURACY_MODE=medium で中精度警告が発生すること', () async {
      // 環境変数 GPS_ACCURACY_MODE=medium で実行されることを前提
      final result = await locationService.getCurrentPosition();

      expect(result.isSuccess, false);
      expect(result.error, contains('GPS精度が中程度です'));
    });

    test('GPS_ACCURACY_MODE=high で高精度で成功すること', () async {
      // 環境変数 GPS_ACCURACY_MODE=high で実行されることを前提
      final result = await locationService.getCurrentPosition();

      expect(result.isSuccess, true);
      expect(result.lat, isNotNull);
      expect(result.lng, isNotNull);
    });
  });
}
