import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 店舗画像をキャッシュ機能付きで表示するウィジェット
class CachedStoreImage extends StatelessWidget {
  /// 画像URL
  final String? imageUrl;

  /// 画像の幅
  final double? width;

  /// 画像の高さ
  final double? height;

  /// ボーダー半径
  final double borderRadius;

  /// フィット方法
  final BoxFit fit;

  const CachedStoreImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: width,
              height: height,
              fit: fit,
              // メモリ効率改善のための設定（最適化）
              memCacheWidth: width?.toInt(),
              memCacheHeight: height?.toInt(),
              maxWidthDiskCache: 300, // ディスクキャッシュサイズ縮小
              maxHeightDiskCache: 300,
              // フェードイン効果でスムーズな読み込み
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 100),
              // 無効なURLのリトライ制限
              errorListener: (exception) {
                // デバッグ環境でのみログ出力（プロダクション環境制御）
                if (kDebugMode) {
                  debugPrint('CachedStoreImage error: $exception');
                }
              },
              placeholder: (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.grey,
                  size: 40,
                  semanticLabel: '店舗画像なし',
                ),
              ),
            )
          : Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.restaurant,
                color: Colors.grey,
                size: 40,
                semanticLabel: '店舗画像なし',
              ),
            ),
    );
  }
}
