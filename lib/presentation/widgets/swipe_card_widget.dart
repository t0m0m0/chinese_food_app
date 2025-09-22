import 'package:flutter/material.dart';
import '../../domain/entities/store.dart';
import 'cached_store_image.dart';

/// マッチングアプリ風のスワイプ可能なカードウィジェット
///
/// Material Design 3準拠で、店舗情報を魅力的に表示し、
/// スワイプやタップ操作に対応したカードを提供します。
class SwipeCardWidget extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const SwipeCardWidget({
    super.key,
    required this.store,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${store.name}の店舗カード',
      button: true,
      child: RepaintBoundary(
        child: Card(
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerLow,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 店舗画像部分（上半分）
                  Expanded(
                    flex: 3,
                    child: _buildImageSection(colorScheme),
                  ),
                  // 店舗情報部分（下半分）
                  Expanded(
                    flex: 2,
                    child: _buildInfoSection(theme, colorScheme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 店舗画像セクションを構築
  Widget _buildImageSection(ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 店舗画像
        CachedStoreImage(
          imageUrl: store.imageUrl,
          fit: BoxFit.cover,
          borderRadius: 0, // カード全体の角丸で処理
        ),
        // グラデーションオーバーレイ（文字の可読性向上）
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 店舗情報セクションを構築
  Widget _buildInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗名
          Text(
            store.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 住所とアクセス情報
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 追加情報表示エリア（将来的にジャンルや予算情報）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '中華料理',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
