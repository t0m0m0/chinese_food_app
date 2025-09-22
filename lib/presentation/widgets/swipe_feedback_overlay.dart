import 'package:flutter/material.dart';

/// スワイプ操作のフィードバックを表示するオーバーレイウィジェット
///
/// 右スワイプ（行きたい）や左スワイプ（興味なし）の際に
/// アニメーション付きフィードバックを提供します。
class SwipeFeedbackOverlay extends StatefulWidget {
  final bool showLike;
  final bool showDislike;
  final Duration animationDuration;

  const SwipeFeedbackOverlay({
    super.key,
    required this.showLike,
    required this.showDislike,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<SwipeFeedbackOverlay> createState() => _SwipeFeedbackOverlayState();
}

class _SwipeFeedbackOverlayState extends State<SwipeFeedbackOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: widget.animationDuration,
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
  }

  @override
  void didUpdateWidget(SwipeFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showLike || widget.showDislike) {
      _scaleController.forward();
      _fadeController.forward();
    } else {
      _scaleController.reverse();
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
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
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      widget.showLike ? colorScheme.primary : colorScheme.error,
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
                      widget.showLike ? Icons.favorite : Icons.thumb_down,
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
            ),
          ),
        ),
      ),
    );
  }
}
