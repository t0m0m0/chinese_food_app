import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/decorative_elements.dart';
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
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppTheme.cardGradient,
                  border: Border.all(
                    color: AppTheme.accentBeige,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // メインコンテンツ
                      Column(
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
                      // 左上のコーナー装飾
                      Positioned(
                        top: 0,
                        left: 0,
                        child: DecorativeElements.cornerDecorationTopLeft(
                          size: 30,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      // 右下に小さな餃子装飾
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Opacity(
                          opacity: 0.15,
                          child: DecorativeElements.gyozaIcon(size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
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
        // レトロフューチャーなグラデーションオーバーレイ
        if (enableGradientOverlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryRed.withValues(alpha: 0.15),
                    AppTheme.textPrimary.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        // 右上に装飾的なアクセント
        if (enableGradientOverlay)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.glowEffect(AppTheme.primaryRed),
              ),
              child: Text(
                '町中華',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.surfaceWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 店舗情報セクションを構築
  Widget _buildInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceWhite,
            AppTheme.surfaceWhite,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗名（太字・大きめ・高コントラスト）
          Flexible(
            child: Text(
              store.name,
              style: AppTheme.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),

          // 住所とアクセス情報（アイコン改善）
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  store.address,
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
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

  /// 個別チップウィジェットを構築（レトロフューチャースタイル）
  Widget _buildChip({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTheme.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
