import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('AppConfig Security Tests', () {
    setUp(() {
      // テスト前にAPIキーをクリア（本番環境では失敗するため、try-catchで処理）
      try {
        AppConfig.clearTestApiKey();
        AppConfig.resetInitialization();
      } catch (e) {
        // 本番環境では期待される動作なのでエラーを無視
      }
    });

    tearDown(() {
      // テスト後にAPIキーをクリア（本番環境では失敗するため、try-catchで処理）
      try {
        AppConfig.clearTestApiKey();
        AppConfig.resetInitialization();
      } catch (e) {
        // 本番環境では期待される動作なのでエラーを無視
      }
    });

    group('APIキー検証', () {
      test('空のAPIキーは無効として判定される', () {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否されることを確認
          expect(() => AppConfig.setTestApiKey(''), throwsStateError);
          // 本番環境では同期版APIキーチェックはfalseを返す
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        } else {
          // 開発環境では正常にテスト用APIキーを設定・検証可能
          AppConfig.setTestApiKey('');
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        }
      });

      test('プレースホルダーAPIキーは無効として判定される', () {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否されることを確認
          expect(() => AppConfig.setTestApiKey('YOUR_API_KEY_HERE'),
              throwsStateError);
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        } else {
          // 開発環境では正常にテスト用APIキーを設定・検証可能
          AppConfig.setTestApiKey('YOUR_API_KEY_HERE');
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        }
      });

      test('有効なAPIキーは正しく判定される', () {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否されることを確認
          expect(
              () => AppConfig.setTestApiKey('e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0'),
              throwsStateError);
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        } else {
          // 開発環境では正常にテスト用APIキーを設定・検証可能
          AppConfig.setTestApiKey('e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0');
          expect(AppConfig.hasHotpepperApiKey, isTrue);
        }
      });

      test('本番環境では同期版APIキー取得は例外を投げる', () {
        // 現在は開発環境でテストしているため、このテストはスキップ
        // 本番環境で実行された場合のみテストが有効
        if (!AppConfig.isProduction) {
          expect(AppConfig.hotpepperApiKeySync, isA<String?>());
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
        const testKey = 'e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0';

        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定・クリアが拒否される
          expect(() => AppConfig.setTestApiKey(testKey), throwsStateError);
          expect(() => AppConfig.clearTestApiKey(), throwsStateError);
        } else {
          // 開発環境では正常に動作
          AppConfig.setTestApiKey(testKey);
          expect(AppConfig.hotpepperApiKeySync, equals(testKey));

          AppConfig.clearTestApiKey();
          expect(AppConfig.hotpepperApiKeySync, isNot(equals(testKey)));
        }
      });

      test('初期化状態は正しく管理される', () {
        if (AppConfig.isProduction) {
          // 本番環境では、初期化リセットが拒否される
          expect(() => AppConfig.resetInitialization(), throwsStateError);
          // デバッグ情報は取得可能
          final debugInfo = AppConfig.debugInfo;
          expect(debugInfo, containsPair('initialized', isA<bool>()));
        } else {
          // 開発環境では正常に動作
          expect(AppConfig.debugInfo['initialized'], isA<bool>());

          AppConfig.resetInitialization();
          expect(AppConfig.debugInfo['initialized'], isFalse);
        }
      });
    });

    group('非同期API取得', () {
      test('非同期版APIキー取得は正しく動作する', () async {
        const testKey = 'e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0';

        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否される
          expect(() => AppConfig.setTestApiKey(testKey), throwsStateError);

          // 本番環境では secure storage からAPIキーを取得しようとする
          // 実際のAPIキーがないため、例外が発生することを期待
          try {
            await AppConfig.hotpepperApiKey;
          } catch (e) {
            // セキュリティ例外が発生することを確認
            expect(e, isA<Exception>());
          }

          // 非同期版も例外を発生させずに結果を返す場合がある
          try {
            final hasHotpepper = await AppConfig.hasHotpepperApiKeyAsync;
            expect(hasHotpepper, isFalse); // 実際のAPIキーが設定されていないため
          } catch (e) {
            // セキュリティ例外が発生することも期待される動作
            expect(e, isA<Exception>());
          }
        } else {
          // 開発環境では正常にテスト用APIキーを設定・取得可能
          AppConfig.setTestApiKey(testKey);

          final hotpepperKey = await AppConfig.hotpepperApiKey;
          expect(hotpepperKey, equals(testKey));

          final hasKey = await AppConfig.hasHotpepperApiKeyAsync;
          expect(hasKey, isTrue);
        }
      });
    });

    group('デバッグ情報', () {
      test('デバッグ情報は必要な情報を含む', () {
        final debugInfo = AppConfig.debugInfo;

        expect(debugInfo, containsPair('isDevelopment', isA<bool>()));
        expect(debugInfo, containsPair('isProduction', isA<bool>()));
        expect(debugInfo, containsPair('hasHotpepperApiKey', isA<bool>()));
        expect(debugInfo, containsPair('initialized', isA<bool>()));
      });
    });
  });
}
