import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// スワイプ操作を補完する手動操作ボタン
///
/// 「行きたい」「興味なし」の2つのFloatingActionButtonを提供し、
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 「興味なし」ボタン（左スワイプと同等の機能）
          RepaintBoundary(
            child: Semantics(
              label: '興味なし',
              hint: '左スワイプと同じ効果。興味がない店舗として記録されます',
              button: true,
              excludeSemantics: !enabled,
              child: FloatingActionButton(
                onPressed: enabled ? _handleDislike : null,
                // Material Design 3準拠のカラーテーマ
                backgroundColor: enabled
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: enabled
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
                // Hero animation競合回避のための一意タグ
                heroTag: 'dislike_button',
                // 有効/無効状態による視覚的フィードバック
                elevation: enabled ? 6 : 2,
                child: const Icon(
                  Icons.thumb_down,
                  size: 28,
                ),
              ),
            ),
          ),

          // 「行きたい」ボタン（右スワイプと同等の機能）
          RepaintBoundary(
            child: Semantics(
              label: '行きたい',
              hint: '右スワイプと同じ効果。行きたい店舗として記録されます',
              button: true,
              excludeSemantics: !enabled,
              child: FloatingActionButton(
                onPressed: enabled ? _handleLike : null,
                // Material Design 3準拠のカラーテーマ
                backgroundColor: enabled
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: enabled
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                // Hero animation競合回避のための一意タグ
                heroTag: 'like_button',
                // 有効/無効状態による視覚的フィードバック
                elevation: enabled ? 6 : 2,
                child: const Icon(
                  Icons.favorite,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 「興味なし」ボタンのハンドラー（ハプティックフィードバック付き）
  void _handleDislike() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onDislike();
  }

  /// 「行きたい」ボタンのハンドラー（ハプティックフィードバック付き）
  void _handleLike() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onLike();
  }
}
