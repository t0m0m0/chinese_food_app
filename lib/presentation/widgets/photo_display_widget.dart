import 'dart:io';
import 'package:flutter/material.dart';

/// 写真を表示・操作するためのウィジェット
class PhotoDisplayWidget extends StatelessWidget {
  final String? imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isLoading;
  final String? errorMessage;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PhotoDisplayWidget({
    super.key,
    this.imagePath,
    this.onTap,
    this.onDelete,
    this.isLoading = false,
    this.errorMessage,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              _buildImageContent(context),
              if (onDelete != null) _buildDeleteButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    if (errorMessage != null) {
      return _buildErrorDisplay(context);
    }

    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return _buildImage();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorDisplay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '写真なし',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Image.file(
      File(imagePath!),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorDisplay(context);
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 20,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
