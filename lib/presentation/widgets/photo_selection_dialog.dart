import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/photo_service.dart';

/// 写真選択方法を選択するダイアログ
class PhotoSelectionDialog extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PhotoSelectionDialog({
    super.key,
    this.title = '写真を選択',
    this.subtitle,
  });

  /// ダイアログを表示して、選択された写真ファイルを返す
  static Future<File?> show(
    BuildContext context, {
    String title = '写真を選択',
    String? subtitle,
  }) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => PhotoSelectionDialog(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitle!),
                const SizedBox(height: 16),
                _buildSelectionButtons(context),
              ],
            )
          : _buildSelectionButtons(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }

  Widget _buildSelectionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('カメラで撮影'),
          onTap: () => _selectFromCamera(context),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('ギャラリーから選択'),
          onTap: () => _selectFromGallery(context),
        ),
      ],
    );
  }

  Future<void> _selectFromCamera(BuildContext context) async {
    try {
      final photoService = PhotoService();
      final file = await photoService.takePhotoFromCamera();
      if (context.mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラでの撮影に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _selectFromGallery(BuildContext context) async {
    try {
      final photoService = PhotoService();
      final file = await photoService.pickPhotoFromGallery();
      if (context.mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ギャラリーからの選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
