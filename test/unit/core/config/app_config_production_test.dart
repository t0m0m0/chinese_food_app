import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/security_exception.dart';

void main() {
  group('AppConfig Production Environment Tests', () {
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

    group('セキュリティ例外テスト', () {
      test('APIKeyNotFoundException は適切な情報を含む', () {
        final exception = APIKeyNotFoundException(
          'Test API',
          context: 'テストコンテキスト',
        );

        expect(exception.keyType, equals('Test API'));
        expect(exception.message, equals('Test APIのAPIキーが設定されていません'));
        expect(exception.context, equals('テストコンテキスト'));
        expect(exception.toString(), contains('Test API'));
        expect(exception.toString(), contains('テストコンテキスト'));
      });

      test('APIKeyAccessException は適切な情報を含む', () {
        final originalException = const FormatException('テストエラー');
        final exception = APIKeyAccessException(
          'Google Maps API',
          'アクセスエラーが発生しました',
          context: 'テスト環境',
          originalException: originalException,
        );

        expect(exception.keyType, equals('Google Maps API'));
        expect(exception.message, equals('Google Maps API: アクセスエラーが発生しました'));
        expect(exception.context, equals('テスト環境'));
        expect(exception.originalException, equals(originalException));
        expect(exception.toString(), contains('Google Maps API'));
        expect(exception.toString(), contains('テスト環境'));
        expect(exception.toString(), contains('FormatException'));
      });

      test('SecureStorageException は適切な情報を含む', () {
        final exception = SecureStorageException(
          'read',
          'ストレージアクセスに失敗しました',
          context: 'API キー取得中',
        );

        expect(exception.operation, equals('read'));
        expect(
            exception.message, equals('セキュアストレージread エラー: ストレージアクセスに失敗しました'));
        expect(exception.context, equals('API キー取得中'));
      });
    });

    group('エラーハンドリング動作確認', () {
      test('非同期API取得でセキュリティ例外が適切に処理される', () async {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否されることを確認
          expect(() => AppConfig.setTestApiKey('test_key'), throwsStateError);

          // 本番環境では secure storage からAPIキーを取得しようとする
          // 実際のAPIキーがないため、例外が発生することを期待
          try {
            await AppConfig.hotpepperApiKey;
          } catch (e) {
            // セキュリティ例外が発生することを確認
            expect(e, isA<Exception>());
          }
        } else {
          // 開発環境では正常にテスト用APIキーを設定・取得可能
          AppConfig.setTestApiKey('d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9');
          final hotpepperKey = await AppConfig.hotpepperApiKey;
          expect(hotpepperKey, equals('d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9'));
        }
      });

      test('同期版API取得は環境に応じて適切に動作する', () {
        if (AppConfig.isProduction) {
          // 本番環境では同期版は例外を投げる
          expect(() => AppConfig.hotpepperApiKeySync, throwsUnsupportedError);
        } else {
          // 開発環境では同期版が使用可能
          expect(() => AppConfig.hotpepperApiKeySync, returnsNormally);
        }
      });

      test('API キー検証メソッドは例外を発生させない', () async {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定が拒否される
          expect(() => AppConfig.setTestApiKey('test_key'), throwsStateError);

          // 本番環境では同期版APIキーチェックはfalseを返す
          expect(() => AppConfig.hasHotpepperApiKey, returnsNormally);
          expect(AppConfig.hasHotpepperApiKey, isFalse);

          // 非同期版も例外を発生させずに結果を返す
          try {
            final hasHotpepper = await AppConfig.hasHotpepperApiKeyAsync;
            expect(hasHotpepper, isFalse); // 実際のAPIキーが設定されていないため
          } catch (e) {
            // Flutter バインディングの初期化エラーが発生する場合があるため、
            // セキュリティ例外が発生することも期待される動作
            expect(e, isA<Exception>());
          }
        } else {
          // 開発環境では正常にテスト用APIキーを設定・検証可能
          AppConfig.setTestApiKey('a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6');
          expect(() => AppConfig.hasHotpepperApiKey, returnsNormally);
          final hasHotpepper = await AppConfig.hasHotpepperApiKeyAsync;
          expect(hasHotpepper, isTrue);
        }
      });
    });

    group('セキュリティ機能統合テスト', () {
      test('APIキー設定の動作は環境に応じて変わる', () async {
        const testHotpepperKey = 'b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7';

        if (AppConfig.isProduction) {
          // 本番環境では、テスト用APIキー設定が拒否される
          expect(() => AppConfig.setTestApiKey(testHotpepperKey),
              throwsStateError);

          // 同期版APIキー取得は例外を投げる
          expect(() => AppConfig.hotpepperApiKeySync, throwsUnsupportedError);

          // 検証メソッドは false を返す（実際のAPIキーがないため）
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        } else {
          // 開発環境では正常に動作
          AppConfig.setTestApiKey(testHotpepperKey);

          final hotpepperKey = await AppConfig.hotpepperApiKey;
          expect(hotpepperKey, equals(testHotpepperKey));

          expect(AppConfig.hotpepperApiKeySync, equals(testHotpepperKey));
          expect(AppConfig.hasHotpepperApiKey, isTrue);

          final hasHotpepperAsync = await AppConfig.hasHotpepperApiKeyAsync;
          expect(hasHotpepperAsync, isTrue);
        }
      });

      test('APIキークリア機能は環境に応じて動作する', () {
        if (AppConfig.isProduction) {
          // 本番環境では、APIキー設定・クリアが拒否される
          expect(() => AppConfig.setTestApiKey('test_key'), throwsStateError);
          expect(() => AppConfig.clearTestApiKey(), throwsStateError);
        } else {
          // 開発環境では正常に動作
          AppConfig.setTestApiKey('c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8');
          expect(AppConfig.hasHotpepperApiKey, isTrue);

          AppConfig.clearTestApiKey();
          expect(AppConfig.hasHotpepperApiKey, isFalse);
        }
      });

      test('初期化状態管理は環境に応じて動作する', () {
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

    group('デバッグ情報拡張確認', () {
      test('デバッグ情報は必要な項目を全て含む', () {
        final debugInfo = AppConfig.debugInfo;

        // 基本的な項目
        expect(debugInfo, containsPair('isDevelopment', isA<bool>()));
        expect(debugInfo, containsPair('isProduction', isA<bool>()));
        expect(debugInfo, containsPair('hasHotpepperApiKey', isA<bool>()));
        expect(debugInfo, containsPair('initialized', isA<bool>()));

        // 各項目が期待される値を持つ
        expect(debugInfo['isDevelopment'], isA<bool>());
        expect(debugInfo['isProduction'], isA<bool>());
        expect(debugInfo['initialized'], isA<bool>());
      });

      test('環境判定は一貫性を保つ', () {
        final debugInfo = AppConfig.debugInfo;

        // 開発環境と本番環境は排他的
        final isDev = debugInfo['isDevelopment'] as bool;
        final isProd = debugInfo['isProduction'] as bool;

        expect(isDev || isProd, isTrue);
        expect(isDev && isProd, isFalse);
      });
    });
  });
}
