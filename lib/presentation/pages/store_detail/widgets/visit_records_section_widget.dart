import 'package:flutter/material.dart';
import '../../../../domain/entities/visit_record.dart';
import 'visit_record_card_widget.dart';

/// 訪問記録セクションウィジェット
///
/// 店舗詳細ページに表示される訪問記録のセクション。
/// 訪問記録がない場合は空状態メッセージを表示し、
/// ある場合は訪問回数とリストを表示する。
class VisitRecordsSectionWidget extends StatelessWidget {
  const VisitRecordsSectionWidget({
    super.key,
    required this.storeId,
    required this.visitRecords,
  });

  final String storeId;
  final List<VisitRecord> visitRecords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションヘッダー
          if (visitRecords.isEmpty)
            _buildEmptyState(theme, colorScheme)
          else
            _buildVisitRecordsList(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'まだ訪問記録がありません',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitRecordsList(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 訪問回数ヘッダー
        Row(
          children: [
            Text(
              '📝 訪問記録 (${visitRecords.length}回)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 訪問記録リスト
        ...visitRecords.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: VisitRecordCardWidget(visitRecord: record),
            )),
      ],
    );
  }
}
