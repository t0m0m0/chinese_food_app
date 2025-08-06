import 'package:flutter/material.dart';
import '../../../../domain/entities/store.dart';

class StoreActionWidget extends StatelessWidget {
  const StoreActionWidget({
    super.key,
    required this.store,
    required this.onStatusChanged,
    required this.onAddVisitRecord,
    required this.onShowMap,
  });

  final Store store;
  final Function(StoreStatus) onStatusChanged;
  final VoidCallback onAddVisitRecord;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _buildStatusSection(context, theme, colorScheme),
        _buildActionButtons(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildStatusSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ステータス変更',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        context,
                        '行きたい',
                        Icons.favorite,
                        StoreStatus.wantToGo,
                        colorScheme.primary,
                        theme,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusButton(
                        context,
                        '行った',
                        Icons.check_circle,
                        StoreStatus.visited,
                        Colors.green,
                        theme,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusButton(
                        context,
                        '興味なし',
                        Icons.block,
                        StoreStatus.bad,
                        Colors.orange,
                        theme,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    IconData icon,
    StoreStatus status,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = store.status == status;
    final semanticsLabel = isSelected ? '$labelが選択されています' : 'ステータスを$labelに変更';

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onStatusChanged(status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: '${store.name}の訪問記録を追加',
              button: true,
              child: FilledButton.icon(
                onPressed: onAddVisitRecord,
                icon: const Icon(Icons.add),
                label: const Text('訪問記録を追加'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: '${store.name}の場所を地図で表示',
              button: true,
              child: OutlinedButton.icon(
                onPressed: onShowMap,
                icon: const Icon(Icons.map),
                label: const Text('地図で表示'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
