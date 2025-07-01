import 'package:flutter/material.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/exceptions/domain_exceptions.dart';

/// Widget for displaying errors in various formats
class ErrorDisplayWidget extends StatelessWidget {
  final AppException exception;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.exception,
    required this.message,
    this.onRetry,
  });

  /// Show error as SnackBar
  static void showError(
      BuildContext context, AppException exception, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show error as AlertDialog
  static void showErrorDialog(
    BuildContext context,
    AppException exception,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          if (onRetry != null && exception is NetworkException)
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
    required AppException exception,
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
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
