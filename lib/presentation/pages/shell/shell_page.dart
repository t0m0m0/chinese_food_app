import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ボトムナビゲーション付きのShellページ
class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swipe),
            label: 'スワイプ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'マイメニュー',
          ),
        ],
      ),
    );
  }

  /// 現在の選択インデックスを計算
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/swipe')) {
      return 0;
    }
    if (location.startsWith('/search')) {
      return 1;
    }
    if (location.startsWith('/my-menu')) {
      return 2;
    }
    return 0;
  }

  /// タブがタップされた時の処理
  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/swipe');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/my-menu');
        break;
    }
  }
}
