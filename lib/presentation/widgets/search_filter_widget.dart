import 'package:flutter/material.dart';
import '../../core/config/search_config.dart';
import '../../core/config/ui_config.dart';

/// 検索フィルター設定ウィジェット
class SearchFilterWidget extends StatelessWidget {
  final int searchRange;
  final int resultCount;
  final void Function(int) onRangeChanged;
  final void Function(int) onCountChanged;

  const SearchFilterWidget({
    super.key,
    required this.searchRange,
    required this.resultCount,
    required this.onRangeChanged,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 検索範囲設定
            Text(
              UiConfig.getSearchFilterLabel('searchRange'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRangeSelector(colorScheme),
            const SizedBox(height: 24),

            // 結果数設定
            Text(
              UiConfig.getSearchFilterLabel('resultCount'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SearchConfig.rangeLabels.entries.map((entry) {
        final rangeValue = entry.key;
        final label = entry.value;
        final isSelected = searchRange == rangeValue;

        return FilterChip(
          label: Text(label),
          tooltip: SearchConfig.getRangeDescription(rangeValue),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onRangeChanged(rangeValue);
            }
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}
