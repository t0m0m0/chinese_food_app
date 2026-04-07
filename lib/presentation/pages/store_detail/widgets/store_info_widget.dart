import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/store_utils.dart';
import '../../../../domain/entities/store.dart';

class StoreInfoWidget extends StatelessWidget {
  const StoreInfoWidget({
    super.key,
    required this.store,
  });

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.accentBeige, width: 1),
        ),
        color: AppTheme.surfaceWhite,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '基本情報',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on,
                '住所',
                store.address,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                '登録日',
                StoreUtils.formatDate(store.createdAt),
              ),
              if (store.memo?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.accentBeige),
                const SizedBox(height: 16),
                Text(
                  'メモ',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentBeige,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    store.memo!,
                    style: AppTheme.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
