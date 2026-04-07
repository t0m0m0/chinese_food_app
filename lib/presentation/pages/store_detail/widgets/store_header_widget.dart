import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/decorative_elements.dart';
import '../../../../core/utils/store_utils.dart';
import '../../../../domain/entities/store.dart';

class StoreHeaderWidget extends StatelessWidget {
  const StoreHeaderWidget({
    super.key,
    required this.store,
  });

  final Store store;

  @override
  Widget build(BuildContext context) {
    final statusColor = StoreUtils.getStatusColor(store.status);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accentCream, AppTheme.surfaceWhite],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.accentBeige,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      StoreUtils.getStatusIcon(store.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: AppTheme.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          StoreUtils.getStatusText(store.status),
                          style: AppTheme.bodyMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: DecorativeElements.cornerDecorationTopLeft(
            size: 24,
            color: AppTheme.primaryRed,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: DecorativeElements.cornerDecorationTopRight(
            size: 20,
            color: AppTheme.goldenAccent,
          ),
        ),
      ],
    );
  }
}
