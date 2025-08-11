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
    final meters = SearchConfig.rangeToMeter(widget.selectedRange) ?? 1000;

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
            const SizedBox(height: 16),
            Slider(
              value: meters.toDouble(),
              min: 300.0,
              max: 3000.0,
              divisions: 4,
              label: '${meters}m',
              onChanged: (value) {
                final range = _metersToRange(value.round());
                widget.onChanged(range);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '現在の設定: ${meters}m',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _metersToRange(int meters) {
    switch (meters) {
      case 300:
        return 1;
      case 500:
        return 2;
      case 1000:
        return 3;
      case 2000:
        return 4;
      case 3000:
        return 5;
      default:
        return 3;
    }
  }
}
