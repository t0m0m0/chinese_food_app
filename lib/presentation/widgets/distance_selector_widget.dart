import 'package:flutter/material.dart';
import '../../core/config/search_config.dart';

/// 距離選択ウィジェット
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// Material Design 3準拠の距離選択UI
class DistanceSelectorWidget extends StatefulWidget {
  final int selectedRange;
  final ValueChanged<int> onChanged;

  const DistanceSelectorWidget({
    super.key,
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  State<DistanceSelectorWidget> createState() => _DistanceSelectorWidgetState();
}

class _DistanceSelectorWidgetState extends State<DistanceSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '検索範囲',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: SearchConfig.rangeToMeters.entries.map((entry) {
                final range = entry.key;
                final meters = entry.value;
                final isSelected = range == widget.selectedRange;

                return FilterChip(
                  label: Text('${meters}m'),
                  selected: isSelected,
                  onSelected: (_) => widget.onChanged(range),
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '現在の設定: ${SearchConfig.rangeToMeter(widget.selectedRange) ?? 1000}m',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
