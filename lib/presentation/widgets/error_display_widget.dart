import 'package:flutter/material.dart';
import '../../core/exceptions/unified_exceptions_export.dart';

/// Widget for displaying errors in various formats
class ErrorDisplayWidget extends StatelessWidget {
  final BaseException exception;
  final String message;
  final VoidCallback? onRetry;

  /// UI constants for consistent styling
  static const double _iconSize = 64.0;
  static const double _spacing = 16.0;

  const ErrorDisplayWidget({
    super.key,
    required this.exception,
    required this.message,
    this.onRetry,
  });

  /// Show error as SnackBar
  static void showError(
      BuildContext context, BaseException exception, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show error as AlertDialog
  static void showErrorDialog(
    BuildContext context,
    BaseException exception,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          if (onRetry != null && exception is UnifiedNetworkException)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('再試行'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Create inline error widget
  static Widget inline({
    required BaseException exception,
    required String message,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplayWidget(
      exception: exception,
      message: message,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: _iconSize,
            color: Theme.of(context).colorScheme.error,
            semanticLabel: 'エラーアイコン',
          ),
          const SizedBox(height: _spacing),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: _spacing),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
}
