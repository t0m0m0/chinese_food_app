import 'package:flutter/material.dart';

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
              '検索範囲',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRangeSelector(colorScheme),
            const SizedBox(height: 24),

            // 結果数設定
            Text(
              '結果数',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCountSlider(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector(ColorScheme colorScheme) {
    final ranges = [
      (1, '300m'),
      (2, '500m'),
      (3, '1000m'),
      (4, '2000m'),
      (5, '3000m'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ranges.map((range) {
        final isSelected = searchRange == range.$1;
        return FilterChip(
          label: Text(range.$2),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onRangeChanged(range.$1);
            }
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildCountSlider(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1件',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${resultCount}件',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              '100件',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: resultCount.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          onChanged: (value) {
            onCountChanged(value.round());
          },
        ),
      ],
    );
  }
}
