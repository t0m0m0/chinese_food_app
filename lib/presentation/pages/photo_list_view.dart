import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_display_widget.dart';

/// 写真一覧を表示する画面
class PhotoListView extends StatefulWidget {
  final String? storeId;
  final String? visitId;

  const PhotoListView({
    super.key,
    this.storeId,
    this.visitId,
  });

  @override
  State<PhotoListView> createState() => _PhotoListViewState();
}

class _PhotoListViewState extends State<PhotoListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
    });
  }

  void _loadPhotos() {
    final provider = context.read<PhotoProvider>();

    if (widget.storeId != null) {
      provider.loadPhotosByStoreId(widget.storeId!);
    } else if (widget.visitId != null) {
      provider.loadPhotosByVisitId(widget.visitId!);
    } else {
      provider.loadAllPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真一覧'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPhotos,
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          if (provider.photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '写真がありません',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: provider.photos.length,
            itemBuilder: (context, index) {
              final photo = provider.photos[index];
              return RepaintBoundary(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: PhotoDisplayWidget(
                    imagePath: photo.filePath,
                    width: 200, // 固定サイズでメモリ最適化
                    height: 200,
                    onTap: () => _showPhotoDetail(context, photo),
                    onDelete: () => _deletePhoto(context, photo.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.storeId != null || widget.visitId != null
          ? FloatingActionButton(
              onPressed: () => _showAddPhotoDialog(context),
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }

  void _showPhotoDetail(BuildContext context, photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhotoDisplayWidget(
              imagePath: photo.filePath,
              width: double.infinity,
              height: 300,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '撮影日時',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    _formatDateTime(photo.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.of(context).pop();
                _addPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.of(context).pop();
                _addPhotoFromGallery();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _addPhotoFromCamera() {
    final provider = context.read<PhotoProvider>();

    if (widget.storeId != null) {
      provider.addPhotoFromCamera(widget.storeId!, visitId: widget.visitId);
    }
  }

  void _addPhotoFromGallery() {
    final provider = context.read<PhotoProvider>();

    if (widget.storeId != null) {
      provider.addPhotoFromGallery(widget.storeId!, visitId: widget.visitId);
    }
  }

  void _deletePhoto(BuildContext context, String photoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PhotoProvider>().deletePhoto(photoId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
