import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/decorative_elements.dart';

/// 統一ローディング状態ウィジェット
class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryRed,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 統一エラー状態ウィジェット
class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'エラーが発生しました',
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecorativeElements.ramenBowl(size: 64),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.errorRed,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 統一空状態ウィジェット
class AppEmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final Widget? icon;

  const AppEmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon ?? DecorativeElements.ramenBowl(size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
