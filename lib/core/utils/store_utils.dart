import 'package:flutter/material.dart';
import '../../domain/entities/store.dart';

/// Store関連のユーティリティ機能を提供するクラス
class StoreUtils {
  StoreUtils._(); // private constructor to prevent instantiation

  /// ステータスに応じた色を返す
  static Color getStatusColor(StoreStatus? status, ColorScheme colorScheme) {
    switch (status) {
      case StoreStatus.wantToGo:
        return Colors.red;
      case StoreStatus.visited:
        return Colors.green;
      case StoreStatus.bad:
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  /// ステータスに応じたアイコンを返す
  static IconData getStatusIcon(StoreStatus? status) {
    switch (status) {
      case StoreStatus.wantToGo:
        return Icons.favorite;
      case StoreStatus.visited:
        return Icons.check_circle;
      case StoreStatus.bad:
        return Icons.block;
      default:
        return Icons.restaurant;
    }
  }

  /// ステータスに応じたテキストを返す
  static String getStatusText(StoreStatus? status) {
    switch (status) {
      case StoreStatus.wantToGo:
        return '行きたい';
      case StoreStatus.visited:
        return '行った';
      case StoreStatus.bad:
        return '興味なし';
      default:
        return '未設定';
    }
  }

  /// 日付をフォーマットして文字列で返す (YYYY/MM/DD形式)
  static String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
