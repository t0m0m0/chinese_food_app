import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/ui_config.dart';

void main() {
  group('UiConfig Tests', () {
    test('should have correct default values', () {
      expect(UiConfig.appName, 'マチアプ');
      expect(UiConfig.appVersion, '1.0.0');
      expect(UiConfig.appDescription, '町中華探索アプリ');
      expect(UiConfig.cardBorderRadius, 14.0);
      expect(UiConfig.defaultPadding, 16.0);
      expect(UiConfig.smallPadding, 8.0);
      expect(UiConfig.largePadding, 24.0);
      expect(UiConfig.extraLargePadding, 32.0);
      expect(UiConfig.defaultMapZoom, 15.0);
      expect(UiConfig.minMapZoom, 10.0);
      expect(UiConfig.maxMapZoom, 20.0);
    });

    test('should validate padding values correctly', () {
      expect(UiConfig.isValidPadding(0), true);
      expect(UiConfig.isValidPadding(50), true);
      expect(UiConfig.isValidPadding(100), true);
      expect(UiConfig.isValidPadding(-1), false);
      expect(UiConfig.isValidPadding(101), false);
    });

    test('should validate border radius values correctly', () {
      expect(UiConfig.isValidBorderRadius(0), true);
      expect(UiConfig.isValidBorderRadius(25), true);
      expect(UiConfig.isValidBorderRadius(50), true);
      expect(UiConfig.isValidBorderRadius(-1), false);
      expect(UiConfig.isValidBorderRadius(51), false);
    });

    test('should validate font size values correctly', () {
      expect(UiConfig.isValidFontSize(8), true);
      expect(UiConfig.isValidFontSize(36), true);
      expect(UiConfig.isValidFontSize(72), true);
      expect(UiConfig.isValidFontSize(7), false);
      expect(UiConfig.isValidFontSize(73), false);
    });

    test('should validate icon size values correctly', () {
      expect(UiConfig.isValidIconSize(12), true);
      expect(UiConfig.isValidIconSize(50), true);
      expect(UiConfig.isValidIconSize(100), true);
      expect(UiConfig.isValidIconSize(11), false);
      expect(UiConfig.isValidIconSize(101), false);
    });

    test('should validate image size values correctly', () {
      expect(UiConfig.isValidImageSize(20), true);
      expect(UiConfig.isValidImageSize(250), true);
      expect(UiConfig.isValidImageSize(500), true);
      expect(UiConfig.isValidImageSize(19), false);
      expect(UiConfig.isValidImageSize(501), false);
    });

    test('should validate animation duration values correctly', () {
      expect(
          UiConfig.isValidAnimationDuration(const Duration(milliseconds: 50)), true);
      expect(UiConfig.isValidAnimationDuration(const Duration(milliseconds: 2500)),
          true);
      expect(UiConfig.isValidAnimationDuration(const Duration(milliseconds: 5000)),
          true);
      expect(
          UiConfig.isValidAnimationDuration(const Duration(milliseconds: 49)), false);
      expect(UiConfig.isValidAnimationDuration(const Duration(milliseconds: 5001)),
          false);
    });

    test('should validate swipe threshold values correctly', () {
      expect(UiConfig.isValidSwipeThreshold(0.1), true);
      expect(UiConfig.isValidSwipeThreshold(0.5), true);
      expect(UiConfig.isValidSwipeThreshold(1.0), true);
      expect(UiConfig.isValidSwipeThreshold(0.09), false);
      expect(UiConfig.isValidSwipeThreshold(1.1), false);
    });

    test('should validate map zoom values correctly', () {
      expect(UiConfig.isValidMapZoom(10.0), true);
      expect(UiConfig.isValidMapZoom(15.0), true);
      expect(UiConfig.isValidMapZoom(20.0), true);
      expect(UiConfig.isValidMapZoom(9.9), false);
      expect(UiConfig.isValidMapZoom(20.1), false);
    });

    test('should provide comprehensive debug info', () {
      final debugInfo = UiConfig.debugInfo;

      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo['appName'], isA<String>());
      expect(debugInfo['appVersion'], isA<String>());
      expect(debugInfo['appDescription'], isA<String>());
      expect(debugInfo['cardBorderRadius'], isA<double>());
      expect(debugInfo['defaultPadding'], isA<double>());
      expect(debugInfo['titleFontSize'], isA<double>());
      expect(debugInfo['defaultIconSize'], isA<double>());
      expect(debugInfo['defaultImageSize'], isA<double>());
      expect(debugInfo['defaultAnimationDuration'], isA<int>());
      expect(debugInfo['swipeThreshold'], isA<double>());
      expect(debugInfo['primaryColor'], isA<String>());
      expect(debugInfo['defaultMapZoom'], isA<double>());
    });

    test('should have correct color types', () {
      expect(UiConfig.primaryColor, isA<Color>());
      expect(UiConfig.secondaryColor, isA<Color>());
      expect(UiConfig.errorColor, isA<Color>());
      expect(UiConfig.successColor, isA<Color>());
      expect(UiConfig.warningColor, isA<Color>());
      expect(UiConfig.backgroundColor, isA<Color>());
      expect(UiConfig.cardBackgroundColor, isA<Color>());
      expect(UiConfig.textColor, isA<Color>());
      expect(UiConfig.subtitleColor, isA<Color>());
      expect(UiConfig.dividerColor, isA<Color>());
    });

    test('should have correct animation durations', () {
      expect(UiConfig.defaultAnimationDuration, const Duration(milliseconds: 300));
      expect(UiConfig.quickAnimationDuration, const Duration(milliseconds: 150));
      expect(UiConfig.slowAnimationDuration, const Duration(milliseconds: 500));
    });

    test('should have correct size values', () {
      expect(UiConfig.titleFontSize, 24.0);
      expect(UiConfig.subtitleFontSize, 18.0);
      expect(UiConfig.bodyFontSize, 16.0);
      expect(UiConfig.captionFontSize, 14.0);
      expect(UiConfig.defaultIconSize, 24.0);
      expect(UiConfig.smallIconSize, 16.0);
      expect(UiConfig.largeIconSize, 32.0);
    });

    test('should have correct layout values', () {
      expect(UiConfig.defaultMargin, 16.0);
      expect(UiConfig.smallMargin, 8.0);
      expect(UiConfig.largeMargin, 24.0);
      expect(UiConfig.cardElevation, 4.0);
      expect(UiConfig.cardMaxWidth, 400.0);
      expect(UiConfig.cardMinHeight, 200.0);
    });

    test('should have correct button values', () {
      expect(UiConfig.buttonHeight, 48.0);
      expect(UiConfig.buttonBorderRadius, 8.0);
      expect(UiConfig.iconButtonSize, 24.0);
    });

    test('should have correct swipe values', () {
      expect(UiConfig.swipeThreshold, 0.3);
      expect(UiConfig.swipeVelocityThreshold, 500.0);
    });
  });
}
