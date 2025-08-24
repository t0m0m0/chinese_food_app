import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_metadata.dart';

void main() {
  group('AppMetadata Tests', () {
    group('アプリ基本情報', () {
      test('正しい日本語アプリ名が取得できる', () {
        expect(AppMetadata.appName, '町中華探索アプリ「マチアプ」');
      });

      test('正しい短縮版アプリ名が取得できる', () {
        expect(AppMetadata.appNameShort, 'マチアプ');
      });

      test('正しいアプリ説明文が取得できる', () {
        const expectedDescription = '町中華を探索・記録するアプリ。スワイプで店舗発見、マップ検索、訪問記録が簡単に！';
        expect(AppMetadata.appDescription, expectedDescription);
      });

      test('正しい詳細説明文が取得できる', () {
        final description = AppMetadata.appDescriptionDetail;
        expect(description.length, greaterThan(100));
        expect(description, contains('町中華'));
        expect(description, contains('スワイプ'));
        expect(description, contains('マップ'));
      });
    });

    group('ストア用メタデータ', () {
      test('Android用パッケージ名が正しい', () {
        expect(AppMetadata.androidPackageName, 'com.machiapp.chinese_food');
      });

      test('iOS用Bundle IDが正しい', () {
        expect(AppMetadata.iosBundleId, 'com.machiapp.chineseFoodApp');
      });

      test('アプリバージョンが正しく設定されている', () {
        expect(AppMetadata.version, isNotEmpty);
        expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(AppMetadata.version), true);
      });

      test('ビルド番号が正しく設定されている', () {
        expect(AppMetadata.buildNumber, isNotEmpty);
        expect(int.tryParse(AppMetadata.buildNumber), isNotNull);
      });
    });

    group('ASO（アプリストア最適化）キーワード', () {
      test('適切なキーワードが含まれている', () {
        final keywords = AppMetadata.asoKeywords;
        expect(keywords, contains('中華料理'));
        expect(keywords, contains('町中華'));
        expect(keywords, contains('レストラン検索'));
        expect(keywords, contains('グルメアプリ'));
        expect(keywords, contains('お店探し'));
      });

      test('キーワードが50文字以内で表現されている', () {
        final keywordsString = AppMetadata.asoKeywordsString;
        expect(keywordsString.length, lessThanOrEqualTo(50));
      });
    });

    group('ストア設定', () {
      test('適切な年齢制限レーティングが設定されている', () {
        expect(AppMetadata.ageRating, 'すべて');
      });

      test('適切なカテゴリが設定されている', () {
        expect(AppMetadata.category, 'フード&ドリンク');
      });

      test('プライバシーポリシーURLが設定されている', () {
        final url = AppMetadata.privacyPolicyUrl;
        expect(url, isNotNull);
        expect(url, startsWith('https://'));
      });
    });

    group('デバッグ情報', () {
      test('メタデータのデバッグ情報が適切に提供される', () {
        final debugInfo = AppMetadata.debugInfo();
        expect(debugInfo, contains('appName'));
        expect(debugInfo, contains('version'));
        expect(debugInfo, contains('androidPackageName'));
      });

      test('すべての必須フィールドが設定されている', () {
        expect(AppMetadata.appName, isNotEmpty);
        expect(AppMetadata.appDescription, isNotEmpty);
        expect(AppMetadata.androidPackageName, isNotEmpty);
        expect(AppMetadata.iosBundleId, isNotEmpty);
        expect(AppMetadata.version, isNotEmpty);
        expect(AppMetadata.buildNumber, isNotEmpty);
      });
    });
  });
}
