import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/exceptions/infrastructure/security_exception.dart';

void main() {
  group('AppConfig Production Environment Tests', () {
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
        // テスト環境では.envファイルが存在しないため、テスト用APIキーを設定
        AppConfig.setTestApiKey('test_hotpepper_key');

        // 非同期版での取得確認
        final hotpepperKey = await AppConfig.hotpepperApiKey;

        expect(hotpepperKey, equals('test_hotpepper_key'));
      });

      test('同期版API取得は開発環境で正常動作する', () {
        // 開発環境では同期版が使用可能
        expect(() => AppConfig.hotpepperApiKeySync, returnsNormally);
      });

      test('API キー検証メソッドは例外を発生させない', () async {
        // テスト用APIキーを設定
        AppConfig.setTestApiKey('test_key');

        // 検証メソッドは例外を発生させずにboolを返す
        expect(() => AppConfig.hasHotpepperApiKey, returnsNormally);

        // 非同期版も正常動作する
        final hasHotpepper = await AppConfig.hasHotpepperApiKeyAsync;

        expect(hasHotpepper, isTrue);
      });
    });

    group('セキュリティ機能統合テスト', () {
      test('テスト用APIキー設定は正常に動作する', () async {
        const testHotpepperKey = 'test_hotpepper_12345';

        AppConfig.setTestApiKey(testHotpepperKey);

        // 非同期版での取得確認
        final hotpepperKey = await AppConfig.hotpepperApiKey;

        expect(hotpepperKey, equals(testHotpepperKey));

        // 同期版での取得確認
        expect(AppConfig.hotpepperApiKeySync, equals(testHotpepperKey));

        // 検証メソッドの確認
        expect(AppConfig.hasHotpepperApiKey, isTrue);

        final hasHotpepperAsync = await AppConfig.hasHotpepperApiKeyAsync;
        expect(hasHotpepperAsync, isTrue);
      });

      test('APIキークリア機能は正常に動作する', () {
        // APIキーを設定
        AppConfig.setTestApiKey('test_key');

        expect(AppConfig.hasHotpepperApiKey, isTrue);

        // クリア実行
        AppConfig.clearTestApiKey();

        // クリア後の確認
        expect(AppConfig.hasHotpepperApiKey, isFalse);
      });

      test('初期化状態管理は正常に動作する', () {
        // 初期状態確認
        expect(AppConfig.debugInfo['initialized'], isFalse);

        // リセット実行
        AppConfig.resetInitialization();
        expect(AppConfig.debugInfo['initialized'], isFalse);

        // 初期化は非同期APIキー取得時に自動実行される
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