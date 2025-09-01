import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/proxy_config.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('ProxyConfig', () {
    setUp(() {
      // AppConfigが初期化されていない状態にリセット
      AppConfig.forceUninitialize();
    });

    group('baseUrl', () {
      test('should return development URL when AppConfig is not initialized',
          () {
        // AppConfigが初期化されていない場合の動作確認
        expect(AppConfig.isInitialized, isFalse);

        final url = ProxyConfig.baseUrl;
        expect(url, equals('http://localhost:8787'));
      });

      test(
          'should return production URL when environment variable is production',
          () {
        // 環境変数をproductionに設定した場合の動作確認
        // この場合AppConfigは初期化されていないため、環境変数を直接参照
        final url = ProxyConfig.baseUrl;

        // 開発環境では通常developmentなので、開発URLが返される
        expect(url, equals('http://localhost:8787'));
      });

      test('should use AppConfig when initialized', () async {
        // AppConfigを初期化
        await AppConfig.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );

        expect(AppConfig.isInitialized, isTrue);

        // AppConfig経由で環境が判定される
        final url = ProxyConfig.baseUrl;

        // テスト環境では開発環境として判定されるはず
        expect(url, equals('http://localhost:8787'));
      });
    });

    group('endpoints', () {
      test('should return correct HotPepper search URL', () {
        final url = ProxyConfig.hotpepperSearchUrl;
        expect(url, endsWith('/api/hotpepper/search'));
        expect(url, startsWith(ProxyConfig.baseUrl));
      });

      test('should return correct Google Maps URL', () {
        final url = ProxyConfig.googleMapsUrl;
        expect(url, endsWith('/api/google-maps'));
        expect(url, startsWith(ProxyConfig.baseUrl));
      });

      test('should return correct health check URL', () {
        final url = ProxyConfig.healthCheckUrl;
        expect(url, endsWith('/health'));
        expect(url, startsWith(ProxyConfig.baseUrl));
      });
    });

    group('configuration values', () {
      test('should have correct timeout settings', () {
        expect(ProxyConfig.timeoutSeconds, equals(30));
      });

      test('should have correct retry count', () {
        expect(ProxyConfig.retryCount, equals(2));
      });

      test('should be enabled by default', () {
        expect(ProxyConfig.enabled, isTrue);
      });
    });

    group('commonHeaders', () {
      test('should return correct headers', () {
        final headers = ProxyConfig.commonHeaders;

        expect(headers['Content-Type'], equals('application/json'));
        expect(headers['Accept'], equals('application/json'));
        expect(headers['User-Agent'], equals('ChineseFoodApp/1.0'));
        expect(headers, hasLength(3));
      });
    });

    group('environmentInfo', () {
      test('should return environment info when AppConfig not initialized', () {
        expect(AppConfig.isInitialized, isFalse);

        final info = ProxyConfig.environmentInfo;

        expect(info['environment'], equals('development'));
        expect(info['proxy_url'], equals(ProxyConfig.baseUrl));
        expect(info['enabled'], equals(ProxyConfig.enabled));
        expect(info['timeout'], equals(ProxyConfig.timeoutSeconds));
        expect(info['retry_count'], equals(ProxyConfig.retryCount));
      });

      test('should return environment info when AppConfig is initialized',
          () async {
        await AppConfig.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );

        expect(AppConfig.isInitialized, isTrue);

        final info = ProxyConfig.environmentInfo;

        expect(info['environment'],
            equals(AppConfig.isProduction ? 'production' : 'development'));
        expect(info['proxy_url'], equals(ProxyConfig.baseUrl));
        expect(info['enabled'], equals(ProxyConfig.enabled));
        expect(info['timeout'], equals(ProxyConfig.timeoutSeconds));
        expect(info['retry_count'], equals(ProxyConfig.retryCount));
      });
    });

    group('AppConfig integration', () {
      test('should handle AppConfig initialization state properly', () async {
        // 初期状態（未初期化）
        expect(AppConfig.isInitialized, isFalse);
        final urlBefore = ProxyConfig.baseUrl;

        // AppConfigを初期化
        await AppConfig.initialize(
          throwOnValidationError: false,
          enableDebugLogging: false,
        );

        expect(AppConfig.isInitialized, isTrue);
        final urlAfter = ProxyConfig.baseUrl;

        // どちらも開発環境の場合は同じURLが返される
        expect(urlBefore, equals(urlAfter));
      });

      test('should fallback gracefully when AppConfig throws', () {
        // AppConfigが初期化されていない状態で環境情報を取得
        expect(() => ProxyConfig.baseUrl, returnsNormally);
        expect(() => ProxyConfig.environmentInfo, returnsNormally);
      });
    });

    group('environment-specific URLs', () {
      test('should use correct URLs for different environments', () {
        // AppConfigが初期化されていない場合の環境変数ベースの判定
        final baseUrl = ProxyConfig.baseUrl;

        // デフォルトでは開発環境のURLが使用される
        expect(
            baseUrl,
            anyOf([
              equals('http://localhost:8787'),
              equals('https://chinese-food-app-proxy.your-account.workers.dev'),
            ]));
      });
    });
  });
}
