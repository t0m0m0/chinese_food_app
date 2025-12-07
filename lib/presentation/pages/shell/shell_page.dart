import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ボトムナビゲーション付きのShellページ
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: child.currentIndex,
        onTap: (index) => child.goBranch(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '見つける',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'エリア',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'マイメニュー',
          ),
        ],
      ),
    );
  }
}
