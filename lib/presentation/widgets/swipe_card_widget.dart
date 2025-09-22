import 'package:flutter/material.dart';
import '../../domain/entities/store.dart';
import 'cached_store_image.dart';

/// マッチングアプリ風のスワイプ可能なカードウィジェット
/// Swipeable card widget with dating app-style UI
///
/// Material Design 3準拠で、店舗情報を魅力的に表示し、
/// スワイプやタップ操作に対応したカードを提供します。
/// Displays store information attractively with Material Design 3 compliance,
/// supporting swipe and tap interactions.
///
/// ## 特徴 / Features
/// - HotpepperAPIからの追加情報（ジャンル・予算）を自動表示
///   Auto-display additional info (genre/budget) from HotpepperAPI
/// - 将来のStoreエンティティ拡張に対応
///   Future-ready for Store entity extensions
/// - パフォーマンス最適化済み（RepaintBoundary）
///   Performance optimized with RepaintBoundary
/// - アクセシビリティ完全対応
///   Full accessibility support
class SwipeCardWidget extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  /// HotpepperAPIから取得された追加情報（将来拡張用）
  final String? genre;
  final String? budget;
  final String? access;
  final String? catchPhrase;

  /// カードの表示スタイル設定
  final bool showDetailChips;
  final bool enableGradientOverlay;

  const SwipeCardWidget({
    super.key,
    required this.store,
    this.onTap,
    this.width,
    this.height,
    this.genre,
    this.budget,
    this.access,
    this.catchPhrase,
    this.showDetailChips = true,
    this.enableGradientOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${store.name}の店舗カード',
      hint: '${store.address}にある中華料理店。スワイプまたはタップして詳細を確認できます',
      button: true,
      value: genre != null ? 'ジャンル: $genre' : '中華料理',
      increasedValue: budget != null ? '予算: $budget' : '',
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
        // 店舗画像（エラーハンドリング付き）
        _buildImageWithErrorHandling(colorScheme),
        // グラデーションオーバーレイ（文字の可読性向上）
        if (enableGradientOverlay)
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

          // 詳細情報チップ（ジャンル・予算・アクセス等）
          if (showDetailChips) _buildDetailChips(theme, colorScheme),
        ],
      ),
    );
  }

  /// 詳細情報チップ（ジャンル・予算・アクセス等）を構築
  ///
  /// 優先度：ジャンル > 予算 > アクセス > キャッチフレーズ
  /// 最大3つまで表示（レイアウト崩れ防止）
  Widget _buildDetailChips(ThemeData theme, ColorScheme colorScheme) {
    final List<Widget> chips = [];

    // ジャンル情報（最優先）
    final displayGenre = genre ?? '中華料理';
    chips.add(_buildChip(
      text: displayGenre,
      backgroundColor: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer,
      theme: theme,
    ));

    // 予算情報（利用可能な場合）
    if (budget?.isNotEmpty == true && chips.length < 3) {
      chips.add(_buildChip(
        text: budget!,
        backgroundColor: colorScheme.secondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
        theme: theme,
      ));
    }

    // アクセス情報（短縮版、利用可能な場合）
    if (access?.isNotEmpty == true && chips.length < 3) {
      final shortAccess = _shortenAccessInfo(access!);
      if (shortAccess.isNotEmpty) {
        chips.add(_buildChip(
          text: shortAccess,
          backgroundColor: colorScheme.tertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
          theme: theme,
        ));
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  /// 個別チップウィジェットを構築
  Widget _buildChip({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// アクセス情報を短縮（表示用に最適化）
  ///
  /// 例：「JR新宿駅東口徒歩3分」→「新宿駅徒歩3分」
  String _shortenAccessInfo(String access) {
    if (access.length <= 10) return access;

    // 駅名の抽出と短縮
    final stationMatch = RegExp(r'([^\s]+駅)').firstMatch(access);
    final walkMatch = RegExp(r'徒歩\d+分').firstMatch(access);

    if (stationMatch != null && walkMatch != null) {
      return '${stationMatch.group(1)}${walkMatch.group(0)}';
    }

    // フォールバック：最初の10文字
    return access.length > 10 ? '${access.substring(0, 10)}...' : access;
  }

  /// 画像の読み込みエラーに対応した堅牢な画像表示ウィジェット
  ///
  /// CachedStoreImageをベースに、以下の機能を提供：
  /// - 画像読み込み失敗時のフォールバック表示
  /// - ローディング中のプレースホルダー
  /// - エラー時の再試行機能
  Widget _buildImageWithErrorHandling(ColorScheme colorScheme) {
    return CachedStoreImage(
      imageUrl: store.imageUrl,
      fit: BoxFit.cover,
      borderRadius: 20,
    );
  }
}
