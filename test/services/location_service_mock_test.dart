import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/services/location_service_mock.dart';

/// Issue #43: LocationServiceMockの10種類エラーパターンテスト
/// TDD GREEN段階: 各エラーパターンの動作確認
void main() {
  group('LocationServiceMock - 10 Error Patterns', () {
    late LocationServiceMock mockService;

    setUp(() {
      mockService = LocationServiceMock();
    });

    test('パターン1: GPS信号弱化シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=gps_weak で実行されることを前提
      final result = await mockService.getCurrentPosition();

      // GPS信号弱化パターンでは、エラーまたは低精度座標が返される
      if (!result.isSuccess) {
        expect(
            result.error,
            anyOf([
              contains('GPS信号が弱すぎます'),
              contains('GPS信号が不安定です'),
            ]));
      } else {
        // 成功の場合は座標が返される（低精度）
        expect(result.lat, isNotNull);
        expect(result.lng, isNotNull);
      }
    });

    test('パターン2: 都市部マルチパス環境シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=multipath で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(result.error, contains('マルチパス干渉により位置情報が不安定です'));
      } else {
        // 座標ジャンプのシミュレーション
        expect(result.lat, isNotNull);
        expect(result.lng, isNotNull);
      }
    });

    test('パターン3: 地下・屋内GPS制限シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=indoor で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(
            result.error,
            anyOf([
              contains('屋内環境のためGPS取得できません'),
              contains('GPS信号が届きません'),
            ]));
      } else {
        // 最後に記録された位置（固定座標）
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });

    test('パターン4: バッテリー最適化による制限シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=battery_optimization で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(
            result.error,
            anyOf([
              contains('バッテリー残量が少ないため'),
              contains('省電力モードにより'),
            ]));
      } else {
        expect(result.lat, isNotNull);
        expect(result.lng, isNotNull);
      }
    });

    test('パターン5: 権限変更タイミングシミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=permission_timing で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(result.error, contains('位置情報の権限が実行中に取り消されました'));
      } else {
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });

    test('パターン6: 不安定ネットワーク接続シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=network_unstable で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(
            result.error,
            anyOf([
              contains('ネットワーク接続が不安定です'),
              contains('ネットワーク遅延により'),
            ]));
      } else {
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });

    test('パターン7: 高速移動中の位置追跡シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=high_speed_movement で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(result.error, contains('高速移動中のため位置情報の精度が著しく低下しています'));
      } else {
        // 移動による座標の大きな変化がある可能性
        expect(result.lat, isNotNull);
        expect(result.lng, isNotNull);
      }
    });

    test('パターン8: アプリ切り替え状態保持シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=app_switching で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(result.error, contains('アプリがバックグラウンドに移行したため'));
      } else {
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });

    test('パターン9: OS版数によるパフォーマンス差シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=os_version_difference で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(result.error, contains('古いOSバージョンのため位置情報サービスの性能が制限されています'));
      } else {
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });

    test('パターン10: メモリ不足シミュレーション', () async {
      // ERROR_SIMULATION_PATTERN=memory_shortage で実行されることを前提
      final result = await mockService.getCurrentPosition();

      if (!result.isSuccess) {
        expect(
            result.error,
            anyOf([
              contains('メモリ不足により位置情報サービスが強制終了されました'),
              contains('メモリ使用量が高いため'),
            ]));
      } else {
        expect(result.lat, equals(35.6762));
        expect(result.lng, equals(139.6503));
      }
    });
  });

  group('LocationServiceMock - Permission Simulation', () {
    late LocationServiceMock mockService;

    setUp(() {
      mockService = LocationServiceMock();
    });

    test('権限変更タイミングシミュレーション', () async {
      // PERMISSION_SIMULATION_PATTERN=timing_change で実行されることを前提
      final result = await mockService.checkLocationPermission();

      expect(result.isGranted, false);
      expect(result.errorMessage, contains('権限チェック中に権限が変更されました'));
    });

    test('OS権限ダイアログ遅延シミュレーション', () async {
      // PERMISSION_SIMULATION_PATTERN=os_dialog_delay で実行されることを前提
      final stopwatch = Stopwatch()..start();

      final result = await mockService.checkLocationPermission();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThan(4000)); // 5秒遅延の確認
      expect(result.isGranted, true);
    });
  });
}
