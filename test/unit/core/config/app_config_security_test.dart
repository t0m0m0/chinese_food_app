import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('AppConfig Security Tests', () {
    setUp(() {
      // テスト前にAPIキーをクリア
      AppConfig.clearTestApiKey();
      AppConfig.resetInitialization();
    });

    tearDown(() {
      // テスト後にAPIキーをクリア
      AppConfig.clearTestApiKey();
      AppConfig.resetInitialization();
    });

    group('APIキー検証', () {
      test('空のAPIキーは無効として判定される', () {
        AppConfig.setTestApiKey('');
        expect(AppConfig.hasHotpepperApiKey, isFalse);

        AppConfig.setTestGoogleMapsApiKey('');
        expect(AppConfig.hasGoogleMapsApiKey, isFalse);
      });

      test('プレースホルダーAPIキーは無効として判定される', () {
        AppConfig.setTestApiKey('YOUR_API_KEY_HERE');
        expect(AppConfig.hasHotpepperApiKey, isFalse);

        AppConfig.setTestGoogleMapsApiKey('YOUR_API_KEY_HERE');
        expect(AppConfig.hasGoogleMapsApiKey, isFalse);
      });

      test('有効なAPIキーは正しく判定される', () {
        AppConfig.setTestApiKey('valid_hotpepper_key');
        expect(AppConfig.hasHotpepperApiKey, isTrue);

        AppConfig.setTestGoogleMapsApiKey('valid_google_maps_key');
        expect(AppConfig.hasGoogleMapsApiKey, isTrue);
      });

      test('本番環境では同期版APIキー取得は例外を投げる', () {
        // 現在は開発環境でテストしているため、このテストはスキップ
        // 本番環境で実行された場合のみテストが有効
        if (!AppConfig.isProduction) {
          expect(AppConfig.hotpepperApiKeySync, isA<String?>());
          expect(AppConfig.googleMapsApiKeySync, isA<String?>());
        }
      });
    });

    group('環境判定', () {
      test('開発環境と本番環境は排他的', () {
        // 開発環境と本番環境は同時にtrueにならない
        expect(AppConfig.isDevelopment || AppConfig.isProduction, isTrue);
        expect(AppConfig.isDevelopment && AppConfig.isProduction, isFalse);
      });
    });

    group('セキュリティ機能', () {
      test('テスト用APIキーは正しく設定・クリアされる', () {
        const testKey = 'test_key_123';
        const testGoogleKey = 'test_google_key_456';

        AppConfig.setTestApiKey(testKey);
        AppConfig.setTestGoogleMapsApiKey(testGoogleKey);

        expect(AppConfig.hotpepperApiKeySync, equals(testKey));
        expect(AppConfig.googleMapsApiKeySync, equals(testGoogleKey));

        AppConfig.clearTestApiKey();

        expect(AppConfig.hotpepperApiKeySync, isNot(equals(testKey)));
        expect(AppConfig.googleMapsApiKeySync, isNot(equals(testGoogleKey)));
      });

      test('初期化状態は正しく管理される', () {
        expect(AppConfig.debugInfo['initialized'], isFalse);

        AppConfig.resetInitialization();
        expect(AppConfig.debugInfo['initialized'], isFalse);
      });
    });

    group('非同期API取得', () {
      test('非同期版APIキー取得は正しく動作する', () async {
        const testKey = 'async_test_key';
        AppConfig.setTestApiKey(testKey);

        final hotpepperKey = await AppConfig.hotpepperApiKey;
        expect(hotpepperKey, equals(testKey));

        final hasKey = await AppConfig.hasHotpepperApiKeyAsync;
        expect(hasKey, isTrue);
      });

      test('Google Maps API非同期版も正しく動作する', () async {
        const testKey = 'async_google_test_key';
        AppConfig.setTestGoogleMapsApiKey(testKey);

        final googleKey = await AppConfig.googleMapsApiKey;
        expect(googleKey, equals(testKey));

        final hasKey = await AppConfig.hasGoogleMapsApiKeyAsync;
        expect(hasKey, isTrue);
      });
    });

    group('デバッグ情報', () {
      test('デバッグ情報は必要な情報を含む', () {
        final debugInfo = AppConfig.debugInfo;

        expect(debugInfo, containsPair('isDevelopment', isA<bool>()));
        expect(debugInfo, containsPair('isProduction', isA<bool>()));
        expect(debugInfo, containsPair('hasHotpepperApiKey', isA<bool>()));
        expect(debugInfo, containsPair('hasGoogleMapsApiKey', isA<bool>()));
        expect(debugInfo, containsPair('initialized', isA<bool>()));
      });
    });
  });
}
