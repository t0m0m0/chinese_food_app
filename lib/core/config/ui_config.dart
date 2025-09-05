import 'package:flutter/material.dart';

/// UI関連の設定を管理するクラス
class UiConfig {
  /// アプリ情報 - ASO最適化対応
  static const String appName = '町中華探索「マチアプ」';
  static const String appShortName = 'マチアプ';
  static const String appVersion = '1.0.0';
  static const String appDescription = '中華料理店を発見・記録するグルメアプリ';

  /// レイアウト設定
  static const double cardBorderRadius = 14.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  /// マージン設定
  static const double defaultMargin = 16.0;
  static const double smallMargin = 8.0;
  static const double largeMargin = 24.0;

  /// カード設定
  static const double cardElevation = 4.0;
  static const double cardMaxWidth = 400.0;
  static const double cardMinHeight = 200.0;

  /// ボタン設定
  static const double buttonHeight = 48.0;
  static const double buttonBorderRadius = 8.0;
  static const double iconButtonSize = 24.0;

  /// フォント設定
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;

  /// アイコン設定
  static const double defaultIconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;

  /// 画像設定
  static const double defaultImageSize = 100.0;
  static const double thumbnailSize = 60.0;
  static const double largeImageSize = 200.0;

  /// アニメーション設定
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  /// スワイプ設定
  static const double swipeThreshold = 0.3;
  static const double swipeVelocityThreshold = 500.0;

  /// 地図設定
  static const double mapZoom = 15.0; // 地図のデフォルトズームレベル

  /// 色設定
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFFF5722);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFE0E0E0);

  /// 設定値の妥当性チェック
  static bool isValidPadding(double padding) {
    return padding >= 0 && padding <= 100;
  }

  /// 設定値の妥当性チェック
  static bool isValidBorderRadius(double radius) {
    return radius >= 0 && radius <= 50;
  }

  /// 設定値の妥当性チェック
  static bool isValidFontSize(double fontSize) {
    return fontSize >= 8 && fontSize <= 72;
  }

  /// 設定値の妥当性チェック
  static bool isValidIconSize(double iconSize) {
    return iconSize >= 12 && iconSize <= 100;
  }

  /// 設定値の妥当性チェック
  static bool isValidImageSize(double imageSize) {
    return imageSize >= 20 && imageSize <= 500;
  }

  /// 設定値の妥当性チェック
  static bool isValidAnimationDuration(Duration duration) {
    return duration.inMilliseconds >= 50 && duration.inMilliseconds <= 5000;
  }

  /// 設定値の妥当性チェック
  static bool isValidSwipeThreshold(double threshold) {
    return threshold >= 0.1 && threshold <= 1.0;
  }

  /// 設定値の妥当性チェック
  static bool isValidMapZoom(double zoom) {
    return zoom >= 1.0 && zoom <= 20.0;
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'appName': appName,
      'appShortName': appShortName,
      'appVersion': appVersion,
      'appDescription': appDescription,
      'cardBorderRadius': cardBorderRadius,
      'defaultPadding': defaultPadding,
      'smallPadding': smallPadding,
      'largePadding': largePadding,
      'extraLargePadding': extraLargePadding,
      'defaultMargin': defaultMargin,
      'smallMargin': smallMargin,
      'largeMargin': largeMargin,
      'cardElevation': cardElevation,
      'cardMaxWidth': cardMaxWidth,
      'cardMinHeight': cardMinHeight,
      'buttonHeight': buttonHeight,
      'buttonBorderRadius': buttonBorderRadius,
      'iconButtonSize': iconButtonSize,
      'titleFontSize': titleFontSize,
      'subtitleFontSize': subtitleFontSize,
      'bodyFontSize': bodyFontSize,
      'captionFontSize': captionFontSize,
      'defaultIconSize': defaultIconSize,
      'smallIconSize': smallIconSize,
      'largeIconSize': largeIconSize,
      'defaultImageSize': defaultImageSize,
      'thumbnailSize': thumbnailSize,
      'largeImageSize': largeImageSize,
      'defaultAnimationDuration': defaultAnimationDuration.inMilliseconds,
      'quickAnimationDuration': quickAnimationDuration.inMilliseconds,
      'slowAnimationDuration': slowAnimationDuration.inMilliseconds,
      'swipeThreshold': swipeThreshold,
      'swipeVelocityThreshold': swipeVelocityThreshold,
      'mapZoom': mapZoom,
      'primaryColor': primaryColor.toString(),
      'secondaryColor': secondaryColor.toString(),
      'errorColor': errorColor.toString(),
      'successColor': successColor.toString(),
      'warningColor': warningColor.toString(),
      'backgroundColor': backgroundColor.toString(),
      'cardBackgroundColor': cardBackgroundColor.toString(),
      'textColor': textColor.toString(),
      'subtitleColor': subtitleColor.toString(),
      'dividerColor': dividerColor.toString(),
    };
  }
}
