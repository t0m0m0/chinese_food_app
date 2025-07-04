import 'package:flutter/material.dart';

/// エラー画面ウィジェット
class ErrorPage extends StatelessWidget {
  /// エラーメッセージ
  final String message;

  /// エラーアクション（任意）
  final VoidCallback? onRetry;

  const ErrorPage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null) ...[
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('再試行'),
                ),
                const SizedBox(height: 16),
              ],
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                child: const Text('ホームに戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
