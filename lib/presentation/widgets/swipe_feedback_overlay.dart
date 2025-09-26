import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// スワイプ操作のフィードバックを表示するオーバーレイウィジェット
/// Overlay widget that displays swipe operation feedback
///
/// 右スワイプ（行きたい）や左スワイプ（興味なし）の際に
/// リッチなアニメーション付きフィードバックを提供します。
/// Provides rich animated feedback for right swipe (want to go)
/// and left swipe (not interested) actions.
///
/// ## アニメーション効果 / Animation Effects
/// - スケール変化（エラスティック） / Scale transition (elastic)
/// - フェード効果 / Fade effects
/// - ハートパーティクル（行きたい時） / Heart particles (when liked)
/// - バウンス効果 / Bounce effects
class SwipeFeedbackOverlay extends StatefulWidget {
  final bool showLike;
  final bool showDislike;
  final Duration animationDuration;
  final bool enableParticleEffect;

  const SwipeFeedbackOverlay({
    super.key,
    required this.showLike,
    required this.showDislike,
    this.animationDuration = const Duration(milliseconds: 500),
    this.enableParticleEffect = true,
  });

  @override
  State<SwipeFeedbackOverlay> createState() => _SwipeFeedbackOverlayState();
}

class _SwipeFeedbackOverlayState extends State<SwipeFeedbackOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // パフォーマンス計測開始 / Start performance measurement
    if (kDebugMode) {
      debugPrint('🎭 SwipeFeedbackOverlay: アニメーション初期化開始');
    }

    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _bounceController = AnimationController(
      duration:
          Duration(milliseconds: widget.animationDuration.inMilliseconds + 200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration:
          Duration(milliseconds: widget.animationDuration.inMilliseconds + 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(SwipeFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // パフォーマンス計測：アニメーション開始時刻記録
    final stopwatch = kDebugMode ? (Stopwatch()..start()) : null;

    // スワイプ操作検出時のアニメーション開始
    if (widget.showLike || widget.showDislike) {
      try {
        _scaleController.forward();
        _fadeController.forward();
        _bounceController.forward();

        // 「行きたい」時のみパーティクル効果を有効化
        if (widget.enableParticleEffect && widget.showLike) {
          _particleController.forward();
        }

        // デバッグ：アニメーション開始ログ
        if (kDebugMode) {
          debugPrint(
              '🎬 SwipeFeedbackOverlay: アニメーション開始 ${widget.showLike ? "LIKE" : "DISLIKE"}');
          debugPrint('   - スケール: ${_scaleController.status}');
          debugPrint('   - フェード: ${_fadeController.status}');
          debugPrint('   - バウンス: ${_bounceController.status}');
          if (widget.enableParticleEffect && widget.showLike) {
            debugPrint('   - パーティクル: ${_particleController.status}');
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ SwipeFeedbackOverlay: アニメーション開始エラー');
          debugPrint('エラー: $e');
          debugPrint('スタックトレース: $stackTrace');
        }
      }
    } else {
      try {
        // フィードバック非表示時はすべてのアニメーションを逆再生
        _scaleController.reverse();
        _fadeController.reverse();
        _bounceController.reverse();
        _particleController.reverse();

        if (kDebugMode) {
          debugPrint('🔄 SwipeFeedbackOverlay: アニメーション終了・逆再生');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ SwipeFeedbackOverlay: アニメーション終了エラー');
          debugPrint('エラー: $e');
          debugPrint('スタックトレース: $stackTrace');
        }
      }
    }

    // パフォーマンス計測結果出力
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      if (stopwatch.elapsedMicroseconds > 1000) {
        // 1ms以上の場合のみログ
        debugPrint(
            '⚡ SwipeFeedbackOverlay: アニメーション開始処理時間 ${stopwatch.elapsedMicroseconds}μs');
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLike && !widget.showDislike) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Stack(
            children: [
              // パーティクル効果（行きたい時のみ）
              if (widget.enableParticleEffect && widget.showLike)
                ..._buildParticleEffects(),

              // メインフィードバック
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: widget.showLike
                                ? colorScheme.primary
                                : colorScheme.error,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.showLike
                                    ? Icons.favorite
                                    : Icons.thumb_down,
                                size: 64,
                                color: widget.showLike
                                    ? colorScheme.onPrimary
                                    : colorScheme.onError,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.showLike ? '行きたい' : '興味なし',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: widget.showLike
                                      ? colorScheme.onPrimary
                                      : colorScheme.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ハートパーティクル効果を構築
  ///
  /// 「行きたい」アクション時に画面上に舞い散るハートエフェクト
  List<Widget> _buildParticleEffects() {
    const particleCount = 8;
    final particles = <Widget>[];

    for (int i = 0; i < particleCount; i++) {
      particles.add(
        AnimatedBuilder(
          animation: _particleAnimation,
          builder: (context, child) {
            final angle = (i * 45.0) * (3.14159 / 180.0); // 45度ずつ配置
            final distance = _particleAnimation.value * 120.0; // 拡散距離
            final opacity = 1.0 - _particleAnimation.value; // フェードアウト

            return Positioned(
              left: MediaQuery.of(context).size.width / 2 +
                  (distance * cos(angle)) -
                  12,
              top: MediaQuery.of(context).size.height / 2 +
                  (distance * sin(angle)) -
                  12,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: 0.5 + (_particleAnimation.value * 0.5),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.pink.withValues(alpha: 0.8),
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return particles;
  }

  /// 数学関数：cos
  double cos(double angle) => math.cos(angle);

  /// 数学関数：sin
  double sin(double angle) => math.sin(angle);
}
