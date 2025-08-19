import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_food_app/core/config/security_config.dart';

void main() {
  group('SecurityConfig', () {
    group('デフォルト設定', () {
      test('プロキシが有効であること', () {
        expect(SecurityConfig.proxyEnabled, isTrue);
      });

      test('デフォルトのセキュリティモードがlegacyであること', () {
        expect(SecurityConfig.securityMode, equals('legacy'));
        expect(SecurityConfig.isLegacyMode, isTrue);
        expect(SecurityConfig.isProxyMode, isFalse);
        expect(SecurityConfig.isSecureMode, isFalse);
      });

      test('デフォルトではAPIキーが除去されていないこと', () {
        expect(SecurityConfig.apiKeysRemoved, isFalse);
      });

      test('デフォルトでAPIキーが必要であること', () {
        expect(SecurityConfig.requiresApiKeys, isTrue);
      });

      test('デフォルトでプロキシが必須でないこと', () {
        expect(SecurityConfig.requiresProxy, isFalse);
      });

      test('デフォルトでフォールバックが有効であること', () {
        expect(SecurityConfig.fallbackEnabled, isTrue);
      });
    });

    group('セキュリティ設定の検証', () {
      test('デフォルト設定では検証エラーがないこと', () {
        final errors = SecurityConfig.validateSecurityConfig();
        expect(errors, isEmpty);
      });

      test('セキュリティ情報が正しく取得できること', () {
        final info = SecurityConfig.securityInfo;

        expect(info['security_mode'], equals('legacy'));
        expect(info['proxy_enabled'], isTrue);
        expect(info['api_keys_removed'], isFalse);
        expect(info['requires_api_keys'], isTrue);
        expect(info['requires_proxy'], isFalse);
        expect(info['fallback_enabled'], isTrue);
        expect(info['proxy_base_url'], isNotEmpty);
      });
    });

    group('セキュリティモード判定', () {
      test('legacyモードの判定ロジック', () {
        // デフォルト設定でlegacyモード
        expect(SecurityConfig.isLegacyMode, isTrue);
        expect(SecurityConfig.requiresApiKeys, isTrue);
        expect(SecurityConfig.fallbackEnabled, isTrue);
      });

      // 注意: 実際の環境変数テストは統合テストで実施
      // ここでは設定値の論理的な一貫性をテスト
    });

    group('設定の一貫性チェック', () {
      test('プロキシベースURLが設定されていること', () {
        expect(SecurityConfig.proxyBaseUrl, isNotEmpty);
        expect(SecurityConfig.proxyBaseUrl, contains('http'));
      });

      test('セキュリティモードが有効な値であること', () {
        final validModes = ['legacy', 'proxy', 'secure'];
        expect(validModes, contains(SecurityConfig.securityMode));
      });
    });
  });
}
