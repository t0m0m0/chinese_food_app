import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/decorative_elements.dart';

/// ボトムナビゲーション付きのShellページ（昭和レトロモダン）
class ShellPage extends StatelessWidget {
  final StatefulNavigationShell child;

  const ShellPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 暖簾モチーフの上部アクセントライン
          DecorativeElements.norenDecoration(
            height: 3,
            color: AppTheme.primaryRed,
          ),
          NavigationBar(
            selectedIndex: child.currentIndex,
            onDestinationSelected: (index) => child.goBranch(index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '見つける',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'エリア',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'マイメニュー',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
