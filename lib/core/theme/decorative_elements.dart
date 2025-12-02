import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 町中華の装飾的要素
///
/// 餃子、ラーメン、チャーハンなどの装飾的なイラストやパターンを提供
class DecorativeElements {
  // ============================
  // 装飾パターン
  // ============================

  /// 餃子の模様（繰り返しパターン用）
  static Widget gyozaPattern({
    double size = 40,
    Color color = AppTheme.secondaryYellow,
    double opacity = 0.1,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GyozaPainter(color: color.withValues(alpha: opacity)),
    );
  }

  /// ラーメンどんぶりアイコン
  static Widget ramenBowl({
    double size = 50,
    Color? color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? AppTheme.secondaryYellow,
            (color ?? AppTheme.secondaryYellow).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '🍜',
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }

  /// 餃子アイコン
  static Widget gyozaIcon({
    double size = 40,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          '🥟',
          style: TextStyle(fontSize: size * 0.8),
        ),
      ),
    );
  }

  /// チャーハンアイコン
  static Widget friedRiceIcon({
    double size = 40,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          '🍚',
          style: TextStyle(fontSize: size * 0.8),
        ),
      ),
    );
  }

  /// 中華鍋アイコン
  static Widget wokIcon({
    double size = 40,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          '🍳',
          style: TextStyle(fontSize: size * 0.8),
        ),
      ),
    );
  }

  /// ビール（中華料理のお供）
  static Widget beerIcon({
    double size = 40,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          '🍺',
          style: TextStyle(fontSize: size * 0.8),
        ),
      ),
    );
  }

  // ============================
  // 背景装飾パターン
  // ============================

  /// 散りばめられた食べ物アイコンの背景
  static Widget foodPatternBackground({
    required Widget child,
    double opacity = 0.05,
  }) {
    return Stack(
      children: [
        // 背景パターン
        Positioned.fill(
          child: CustomPaint(
            painter: _FoodPatternPainter(opacity: opacity),
          ),
        ),
        // コンテンツ
        child,
      ],
    );
  }

  /// 中華模様の装飾ボーダー
  static BoxDecoration chinesePatternBorder({
    Color color = AppTheme.primaryRed,
    double borderWidth = 2,
  }) {
    return BoxDecoration(
      border: Border.all(
        color: color,
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(8),
      // 中華風の角飾り（イメージ）
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      ],
    );
  }

  /// 提灯風の装飾円
  static Widget lanternDecoration({
    double size = 60,
    Color color = AppTheme.primaryRed,
  }) {
    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.3),
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: AppTheme.glowEffect(color),
      ),
      child: Center(
        child: Text(
          '中',
          style: AppTheme.headlineSmall.copyWith(
            color: AppTheme.surfaceWhite,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  /// 波線装飾（中華風の湯気イメージ）
  static Widget steamDecoration({
    double width = 100,
    double height = 30,
    Color color = AppTheme.secondaryYellow,
  }) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SteamPainter(color: color.withValues(alpha: 0.3)),
    );
  }

  // ============================
  // コーナー装飾
  // ============================

  /// 中華風コーナー装飾（左上）
  static Widget cornerDecorationTopLeft({
    double size = 40,
    Color color = AppTheme.primaryRed,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ChineseCornerPainter(
        color: color.withValues(alpha: 0.3),
        corner: Corner.topLeft,
      ),
    );
  }

  /// 中華風コーナー装飾（右上）
  static Widget cornerDecorationTopRight({
    double size = 40,
    Color color = AppTheme.primaryRed,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ChineseCornerPainter(
        color: color.withValues(alpha: 0.3),
        corner: Corner.topRight,
      ),
    );
  }
}

// ============================
// カスタムペインター
// ============================

/// 餃子の形を描画
class _GyozaPainter extends CustomPainter {
  final Color color;

  _GyozaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 餃子の半月形
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.7,
      size.width * 0.2,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);

    // ひだの線
    final linePaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.3 + i * 0.1);
      canvas.drawLine(
        Offset(x, size.height * 0.4),
        Offset(x, size.height * 0.6),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 食べ物パターンの背景
class _FoodPatternPainter extends CustomPainter {
  final double opacity;

  _FoodPatternPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryRed.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // ランダムに配置された餃子・ラーメンのパターン
    final random = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.9),
    ];

    for (final offset in random) {
      // 小さな円（ラーメンの具材イメージ）
      canvas.drawCircle(offset, 8, paint);

      // 餃子の形
      final path = Path();
      path.moveTo(offset.dx - 10, offset.dy);
      path.quadraticBezierTo(
        offset.dx,
        offset.dy - 8,
        offset.dx + 10,
        offset.dy,
      );
      path.quadraticBezierTo(
        offset.dx,
        offset.dy + 5,
        offset.dx - 10,
        offset.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 湯気の波線
class _SteamPainter extends CustomPainter {
  final Color color;

  _SteamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveCount = 3;
    final waveWidth = size.width / waveCount;

    path.moveTo(0, size.height * 0.5);

    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth;
      path.quadraticBezierTo(
        x + waveWidth * 0.25,
        0,
        x + waveWidth * 0.5,
        size.height * 0.5,
      );
      path.quadraticBezierTo(
        x + waveWidth * 0.75,
        size.height,
        x + waveWidth,
        size.height * 0.5,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// コーナー位置
enum Corner { topLeft, topRight, bottomLeft, bottomRight }

/// 中華風コーナー装飾
class _ChineseCornerPainter extends CustomPainter {
  final Color color;
  final Corner corner;

  _ChineseCornerPainter({required this.color, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    switch (corner) {
      case Corner.topLeft:
        // 左上のL字型装飾
        path.moveTo(0, size.height * 0.3);
        path.lineTo(0, 0);
        path.lineTo(size.width * 0.3, 0);

        // 内側の装飾線
        path.moveTo(size.width * 0.1, size.height * 0.1);
        path.lineTo(size.width * 0.1, size.height * 0.2);
        path.moveTo(size.width * 0.1, size.height * 0.1);
        path.lineTo(size.width * 0.2, size.height * 0.1);
        break;

      case Corner.topRight:
        // 右上のL字型装飾
        path.moveTo(size.width, size.height * 0.3);
        path.lineTo(size.width, 0);
        path.lineTo(size.width * 0.7, 0);

        // 内側の装飾線
        path.moveTo(size.width * 0.9, size.height * 0.1);
        path.lineTo(size.width * 0.9, size.height * 0.2);
        path.moveTo(size.width * 0.9, size.height * 0.1);
        path.lineTo(size.width * 0.8, size.height * 0.1);
        break;

      case Corner.bottomLeft:
      case Corner.bottomRight:
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
