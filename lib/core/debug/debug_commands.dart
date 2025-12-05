import 'package:flutter/foundation.dart';
import '../../presentation/providers/store_provider.dart';

/// デバッグ用コマンドクラス
///
/// Flutter DevToolsのコンソールから直接実行できるデバッグコマンド
///
/// 使い方:
/// 1. アプリを起動 (flutter run)
/// 2. Flutter DevToolsでコンソールを開く
/// 3. 以下のコマンドを実行:
///    ```dart
///    await DebugCommands.deleteAllStores();
///    ```
class DebugCommands {
  static StoreProvider? _storeProvider;

  /// StoreProviderをセット（main.dartで初期化時に呼ぶ）
  static void initialize(StoreProvider provider) {
    _storeProvider = provider;
    debugPrint('[DebugCommands] 🔧 初期化完了');
  }

  /// 全店舗削除コマンド
  static Future<void> deleteAllStores() async {
    if (_storeProvider == null) {
      debugPrint('[DebugCommands] ❌ エラー: StoreProviderが初期化されていません');
      return;
    }

    debugPrint('[DebugCommands] 🗑️ 全店舗削除を開始...');
    try {
      await _storeProvider!.deleteAllStores();
      debugPrint('[DebugCommands] ✅ 全店舗削除が完了しました');
    } catch (e) {
      debugPrint('[DebugCommands] ❌ エラー: $e');
    }
  }

  /// 店舗数を表示
  static void showStoreCount() {
    if (_storeProvider == null) {
      debugPrint('[DebugCommands] ❌ エラー: StoreProviderが初期化されていません');
      return;
    }

    final count = _storeProvider!.stores.length;
    debugPrint('[DebugCommands] 📊 DB内の店舗数: $count件');
    debugPrint(
        '[DebugCommands]   - 行きたい: ${_storeProvider!.wantToGoStores.length}件');
    debugPrint(
        '[DebugCommands]   - 行った: ${_storeProvider!.visitedStores.length}件');
    debugPrint(
        '[DebugCommands]   - 興味なし: ${_storeProvider!.badStores.length}件');
  }

  /// ヘルプメッセージを表示
  static void help() {
    debugPrint('''
[DebugCommands] 📖 利用可能なコマンド:

  DebugCommands.deleteAllStores()  - 全店舗を削除
  DebugCommands.showStoreCount()   - 店舗数を表示
  DebugCommands.help()             - このヘルプを表示

例:
  await DebugCommands.deleteAllStores();
  DebugCommands.showStoreCount();
''');
  }
}
