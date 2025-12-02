import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// マチアプのデザインシステム
///
/// コンセプト: 「レトロフューチャー × 日本の町中華文化」
/// - 温かみのある赤・オレンジのグラデーション
/// - ノスタルジックな昭和感とモダンな洗練性の融合
/// - 大胆なタイポグラフィとアニメーション
class AppTheme {
  // ============================
  // カラーパレット
  // ============================

  /// メインカラー: 町中華の赤提灯を想起させる温かみのある朱色
  static const Color primaryRed = Color(0xFFE63946);
  static const Color primaryRedDark = Color(0xFFB8242D);
  static const Color primaryRedLight = Color(0xFFFF6B76);

  /// セカンダリカラー: ラーメンの卵黄のような温かいオレンジ
  static const Color secondaryYellow = Color(0xFFFFB703);
  static const Color secondaryYellowDark = Color(0xFFE69500);
  static const Color secondaryYellowLight = Color(0xFFFFCD3C);

  /// アクセントカラー: 餃子の皮のようなクリーム色
  static const Color accentCream = Color(0xFFFFF8E7);
  static const Color accentBeige = Color(0xFFE8D5B7);

  /// 背景カラー: 柔らかいグラデーションベース
  static const Color backgroundLight = Color(0xFFFFFBF5);
  static const Color backgroundDark = Color(0xFF1A1A1A);

  /// テキストカラー: 醤油のような深い茶色
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);

  /// サーフェスカラー
  static const Color surfaceWhite = Color(0xFFFFFFFE);
  static const Color surfaceGray = Color(0xFFF5F5F5);

  /// ステータスカラー
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color errorRed = Color(0xFFEF476F);
  static const Color warningOrange = Color(0xFFFF9F1C);

  // ============================
  // グラデーション
  // ============================

  /// メイングラデーション: 提灯の灯りのような温かみ
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, secondaryYellow],
    stops: [0.3, 0.9],
  );

  /// カードグラデーション: 柔らかな奥行き
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceWhite, accentCream],
    stops: [0.0, 1.0],
  );

  /// 背景グラデーション: 温かみのある空間
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, accentCream],
    stops: [0.0, 1.0],
  );

  // ============================
  // シャドウ & エフェクト
  // ============================

  /// ソフトシャドウ（カード用）
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryRed.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: secondaryYellow.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ];

  /// ストロングシャドウ（アクティブ要素用）
  static List<BoxShadow> get strongShadow => [
        BoxShadow(
          color: primaryRed.withValues(alpha: 0.2),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -8,
        ),
      ];

  /// グローエフェクト（ボタン・アクティブ状態）
  static List<BoxShadow> glowEffect(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 24,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 48,
          spreadRadius: 8,
        ),
      ];

  // ============================
  // タイポグラフィ
  // ============================

  /// Display Font: レトロフューチャーな見出し（Noto Serif JP - 重厚感）
  static TextStyle get displayLarge => GoogleFonts.notoSerifJp(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
        color: textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.notoSerifJp(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.16,
        color: textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.notoSerifJp(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: textPrimary,
      );

  /// Headline Font: 力強い見出し（Zen Maru Gothic - 丸ゴシック）
  static TextStyle get headlineLarge => GoogleFonts.zenMaruGothic(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
        color: textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.zenMaruGothic(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.29,
        color: textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.zenMaruGothic(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.33,
        color: textPrimary,
      );

  /// Title Font: カード・セクションタイトル（Zen Maru Gothic）
  static TextStyle get titleLarge => GoogleFonts.zenMaruGothic(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.zenMaruGothic(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        color: textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.zenMaruGothic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: textPrimary,
      );

  /// Body Font: 本文（Noto Sans JP - 読みやすさ重視）
  static TextStyle get bodyLarge => GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.notoSansJp(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: textSecondary,
      );

  /// Label Font: ボタン・ラベル（Zen Maru Gothic）
  static TextStyle get labelLarge => GoogleFonts.zenMaruGothic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.zenMaruGothic(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
        color: textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.zenMaruGothic(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
        color: textSecondary,
      );

  // ============================
  // ThemeData生成
  // ============================

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: primaryRed,
      onPrimary: surfaceWhite,
      primaryContainer: primaryRedLight,
      onPrimaryContainer: textPrimary,
      secondary: secondaryYellow,
      onSecondary: textPrimary,
      secondaryContainer: secondaryYellowLight,
      onSecondaryContainer: textPrimary,
      tertiary: accentCream,
      onTertiary: textPrimary,
      error: errorRed,
      onError: surfaceWhite,
      surface: surfaceWhite,
      onSurface: textPrimary,
      surfaceContainerLowest: backgroundLight,
      surfaceContainerLow: accentCream,
      surfaceContainer: surfaceGray,
      outline: textTertiary,
      outlineVariant: accentBeige,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // テキストテーマ
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),

      // カードテーマ
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        color: surfaceWhite,
        shadowColor: primaryRed,
      ),

      // AppBarテーマ
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: headlineMedium,
      ),

      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: labelLarge,
        ),
      ),

      // Chipテーマ
      chipTheme: ChipThemeData(
        backgroundColor: accentCream,
        labelStyle: labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // InputDecorationテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: accentCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // BottomNavigationBarテーマ
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryRed,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Dividerテーマ
      dividerTheme: const DividerThemeData(
        color: accentBeige,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
