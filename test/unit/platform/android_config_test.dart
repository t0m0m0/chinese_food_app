import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Android Configuration Tests', () {
    group('strings.xml設定', () {
      test('アプリ名が日本語で設定されている', () {
        final stringsFile = File('android/app/src/main/res/values/strings.xml');
        expect(stringsFile.existsSync(), true,
            reason: 'strings.xmlファイルが存在する必要があります');

        final content = stringsFile.readAsStringSync();
        expect(content, contains('app_name'),
            reason: 'app_nameキーが定義されている必要があります');
        expect(content, contains('町中華探索アプリ「マチアプ」'),
            reason: '日本語アプリ名が設定されている必要があります');
      });

      test('Google Maps APIキーが適切に設定されている', () {
        final stringsFile = File('android/app/src/main/res/values/strings.xml');
        final content = stringsFile.readAsStringSync();

        expect(content, contains('google_maps_api_key'),
            reason: 'Google Maps APIキーが定義されている必要があります');
        // CI環境用のダミーキーまたは実際のキーが設定されていることを確認
        expect(content, contains('AIzaSy'), reason: 'APIキー形式が正しい必要があります');
      });
    });

    group('AndroidManifest.xml設定', () {
      test('アプリケーション名が適切に設定されている', () {
        final manifestFile = File('android/app/src/main/AndroidManifest.xml');
        expect(manifestFile.existsSync(), true,
            reason: 'AndroidManifest.xmlが存在する必要があります');

        final content = manifestFile.readAsStringSync();
        // android:labelが@string/app_nameを参照するか、直接日本語名が設定されている
        expect(
            content,
            anyOf([
              contains('android:label="@string/app_name"'),
              contains('android:label="町中華探索アプリ「マチアプ」"')
            ]),
            reason: 'アプリケーション名が適切に設定されている必要があります');
      });

      test('必要な権限が適切に設定されている', () {
        final manifestFile = File('android/app/src/main/AndroidManifest.xml');
        final content = manifestFile.readAsStringSync();

        // 位置情報権限
        expect(content, contains('ACCESS_FINE_LOCATION'),
            reason: '精密位置情報権限が必要です');
        expect(content, contains('ACCESS_COARSE_LOCATION'),
            reason: '大まかな位置情報権限が必要です');

        // ネットワーク権限
        expect(content, contains('INTERNET'), reason: 'インターネット権限が必要です');

        // カメラ・ストレージ権限
        expect(content, contains('CAMERA'), reason: 'カメラ権限が必要です');
        expect(content, contains('READ_EXTERNAL_STORAGE'),
            reason: '外部ストレージ読み取り権限が必要です');
      });
    });

    group('build.gradle設定', () {
      test('パッケージ名が本番用に設定されている', () {
        final buildGradleFile = File('android/app/build.gradle');
        expect(buildGradleFile.existsSync(), true,
            reason: 'build.gradleが存在する必要があります');

        final content = buildGradleFile.readAsStringSync();
        expect(content, contains('com.machiapp.chinese_food'),
            reason: '本番用パッケージ名が設定されている必要があります');
      });

      test('minSdkVersionが適切に設定されている', () {
        final buildGradleFile = File('android/app/build.gradle');
        final content = buildGradleFile.readAsStringSync();

        expect(content, contains('minSdk'),
            reason: 'minSdkVersionが設定されている必要があります');
        // Android 5.0 (API level 21) 以上をサポート
        expect(content, contains(RegExp(r'minSdk\s*=\s*([2-9]\d|[3-9][0-9])')),
            reason: 'minSdkVersionは21以上である必要があります');
      });

      test('リリースビルド設定が適切である', () {
        final buildGradleFile = File('android/app/build.gradle');
        final content = buildGradleFile.readAsStringSync();

        expect(content, contains('buildTypes'),
            reason: 'buildTypesが設定されている必要があります');
        expect(content, contains('release'), reason: 'releaseビルド設定が必要です');
        expect(content, contains('minifyEnabled'), reason: '難読化設定が必要です');
      });
    });

    group('アイコン設定', () {
      test('各密度のアイコンが存在する', () {
        final iconDensities = [
          'mipmap-mdpi',
          'mipmap-hdpi',
          'mipmap-xhdpi',
          'mipmap-xxhdpi',
          'mipmap-xxxhdpi',
        ];

        for (final density in iconDensities) {
          final iconFile =
              File('android/app/src/main/res/$density/ic_launcher.png');
          expect(iconFile.existsSync(), true,
              reason: '$densityのアイコンファイルが存在する必要があります');
        }
      });
    });
  });
}
