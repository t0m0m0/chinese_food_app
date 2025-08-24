import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('iOS Configuration Tests', () {
    group('Info.plist設定', () {
      test('CFBundleDisplayNameが日本語で設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        expect(infoPlistFile.existsSync(), true,
            reason: 'Info.plistファイルが存在する必要があります');

        final content = infoPlistFile.readAsStringSync();
        expect(content, contains('CFBundleDisplayName'),
            reason: 'CFBundleDisplayNameキーが定義されている必要があります');
        expect(content, contains('町中華探索アプリ「マチアプ」'),
            reason: '日本語アプリ名が設定されている必要があります');
      });

      test('CFBundleNameが適切に設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        final content = infoPlistFile.readAsStringSync();

        expect(content, contains('CFBundleName'),
            reason: 'CFBundleNameが定義されている必要があります');
        // 技術的な名前またはマチアプが設定されている
        expect(content,
            anyOf([contains('machiapp'), contains('chinese_food_app')]),
            reason: 'バンドル名が適切に設定されている必要があります');
      });

      test('CFBundleIdentifierが本番用に設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        final content = infoPlistFile.readAsStringSync();

        expect(content, contains('CFBundleIdentifier'),
            reason: 'CFBundleIdentifierが定義されている必要があります');
        expect(content, contains('\$(PRODUCT_BUNDLE_IDENTIFIER)'),
            reason: 'Bundle IDが変数で管理されている必要があります');
      });

      test('位置情報権限の説明が適切に設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        final content = infoPlistFile.readAsStringSync();

        expect(content, contains('NSLocationWhenInUseUsageDescription'),
            reason: '位置情報権限の説明が必要です');
        expect(content, contains('中華料理店を検索するために位置情報を使用します'),
            reason: '日本語での適切な説明が必要です');
      });

      test('カメラ・写真権限の説明が適切に設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        final content = infoPlistFile.readAsStringSync();

        expect(content, contains('NSCameraUsageDescription'),
            reason: 'カメラ権限の説明が必要です');
        expect(content, contains('NSPhotoLibraryUsageDescription'),
            reason: 'フォトライブラリ権限の説明が必要です');
        expect(content, contains('写真'), reason: '日本語での適切な説明が必要です');
      });

      test('サポートする画面向きが適切に設定されている', () {
        final infoPlistFile = File('ios/Runner/Info.plist');
        final content = infoPlistFile.readAsStringSync();

        expect(content, contains('UISupportedInterfaceOrientations'),
            reason: 'サポートする画面向きが定義されている必要があります');
        expect(content, contains('UIInterfaceOrientationPortrait'),
            reason: 'ポートレート向きはサポートが必要です');
      });
    });

    group('project.pbxproj設定', () {
      test('Bundle IDが本番用に設定されている', () {
        final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
        expect(projectFile.existsSync(), true,
            reason: 'project.pbxprojが存在する必要があります');

        final content = projectFile.readAsStringSync();
        expect(content, contains('PRODUCT_BUNDLE_IDENTIFIER'),
            reason: 'PRODUCT_BUNDLE_IDENTIFIERが設定されている必要があります');
        expect(content, contains('com.machiapp.chineseFoodApp'),
            reason: '本番用Bundle IDが設定されている必要があります');
      });

      test('Code Signing設定が準備されている', () {
        final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
        final content = projectFile.readAsStringSync();

        expect(content, contains('CODE_SIGN_IDENTITY'),
            reason: 'Code Signing設定が必要です');
        expect(content, contains('iPhone Developer'), reason: '開発用証明書設定が必要です');
      });

      test('iOS deployment targetが適切に設定されている', () {
        final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
        final content = projectFile.readAsStringSync();

        expect(content, contains('IPHONEOS_DEPLOYMENT_TARGET'),
            reason: 'iOS deployment targetが設定されている必要があります');
      });
    });

    group('アイコン設定', () {
      test('AppIcon.appiconsetが存在する', () {
        final appIconDir =
            Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
        expect(appIconDir.existsSync(), true,
            reason: 'AppIcon.appiconsetディレクトリが存在する必要があります');
      });

      test('Contents.jsonが適切に設定されている', () {
        final contentsFile =
            File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json');
        expect(contentsFile.existsSync(), true,
            reason: 'Contents.jsonが存在する必要があります');

        final content = contentsFile.readAsStringSync();
        expect(content, contains('1024x1024'),
            reason: 'App Store用1024x1024アイコンが設定されている必要があります');
      });

      test('必要なアイコンサイズが存在する', () {
        final requiredIcons = [
          'Icon-App-20x20@2x.png', // 40x40
          'Icon-App-20x20@3x.png', // 60x60
          'Icon-App-29x29@2x.png', // 58x58
          'Icon-App-29x29@3x.png', // 87x87
          'Icon-App-40x40@2x.png', // 80x80
          'Icon-App-40x40@3x.png', // 120x120
          'Icon-App-60x60@2x.png', // 120x120
          'Icon-App-60x60@3x.png', // 180x180
          'Icon-App-1024x1024@1x.png', // 1024x1024
        ];

        for (final iconName in requiredIcons) {
          final iconFile =
              File('ios/Runner/Assets.xcassets/AppIcon.appiconset/$iconName');
          expect(iconFile.existsSync(), true,
              reason: '$iconNameファイルが存在する必要があります');
        }
      });
    });
  });
}
