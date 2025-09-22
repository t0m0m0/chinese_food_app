import 'package:flutter/material.dart';

/// スワイプ操作を補完する手動操作ボタン
///
/// 「行きたい」「興味なし」の2つのFloatingActionButtonを提供し、
/// スワイプが難しい場合やより確実な操作が必要な場合に使用します。
class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final bool enabled;

  const SwipeActionButtons({
    super.key,
    required this.onDislike,
    required this.onLike,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 「興味なし」ボタン
        Semantics(
          label: '興味なし',
          button: true,
          child: FloatingActionButton(
            onPressed: enabled ? onDislike : null,
            backgroundColor: enabled
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
            foregroundColor: enabled
                ? colorScheme.onErrorContainer
                : colorScheme.onSurfaceVariant,
            heroTag: 'dislike_button',
            elevation: enabled ? 6 : 2,
            child: const Icon(
              Icons.thumb_down,
              size: 28,
            ),
          ),
        ),

        // 「行きたい」ボタン
        Semantics(
          label: '行きたい',
          button: true,
          child: FloatingActionButton(
            onPressed: enabled ? onLike : null,
            backgroundColor: enabled
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            foregroundColor: enabled
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            heroTag: 'like_button',
            elevation: enabled ? 6 : 2,
            child: const Icon(
              Icons.favorite,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
