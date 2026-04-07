import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// スワイプ操作を補完する手動操作ボタン（昭和レトロモダン）
///
/// 「行きたい」「興味なし」の2つのアクションボタンを提供し、
/// スワイプが難しい場合やより確実な操作が必要な場合に使用します。
///
/// ## パフォーマンス最適化
/// - RepaintBoundary による再描画最適化
/// - enabled 状態のみで再構築制御
/// - ボタンタップ時のハプティックフィードバック
class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final bool enabled;
  final bool enableHapticFeedback;

  const SwipeActionButtons({
    super.key,
    required this.onDislike,
    required this.onLike,
    this.enabled = true,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 「興味なし」ボタン（左スワイプと同等の機能）
          RepaintBoundary(
            child: Semantics(
              label: '興味なし',
              hint: '左スワイプと同じ効果。興味がない店舗として記録されます',
              button: true,
              excludeSemantics: !enabled,
              child: _RetroActionButton(
                onPressed: enabled ? _handleDislike : null,
                icon: Icons.block,
                color: AppTheme.warningOrange,
                lightColor: AppTheme.warningOrange.withValues(alpha: 0.3),
                enabled: enabled,
                heroTag: 'dislike_button',
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 中央のレストランアイコン装飾
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentCream,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentBeige,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.restaurant,
              size: 18,
              color: enabled ? AppTheme.textSecondary : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(width: 24),
          // 「行きたい」ボタン（右スワイプと同等の機能）
          RepaintBoundary(
            child: Semantics(
              label: '行きたい',
              hint: '右スワイプと同じ効果。行きたい店舗として記録されます',
              button: true,
              excludeSemantics: !enabled,
              child: _RetroActionButton(
                onPressed: enabled ? _handleLike : null,
                icon: Icons.favorite,
                color: AppTheme.primaryRed,
                lightColor: AppTheme.primaryRedLight,
                enabled: enabled,
                heroTag: 'like_button',
                showGlow: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDislike() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onDislike();
  }

  void _handleLike() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onLike();
  }
}

/// レトロ風アクションボタン（提灯グロー効果付き）
class _RetroActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final bool enabled;
  final String heroTag;
  final bool showGlow;

  const _RetroActionButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.enabled,
    required this.heroTag,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: enabled && showGlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: 68,
        height: 68,
        child: FloatingActionButton(
          onPressed: onPressed,
          heroTag: heroTag,
          elevation: enabled ? 4 : 1,
          backgroundColor: enabled
              ? lightColor.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest,
          foregroundColor: enabled ? color : colorScheme.onSurfaceVariant,
          shape: CircleBorder(
            side: BorderSide(
              color: enabled
                  ? color.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Icon(icon, size: 30),
        ),
      ),
    );
  }
}
