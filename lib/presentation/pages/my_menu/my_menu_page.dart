import 'package:flutter/material.dart';

class MyMenuPage extends StatefulWidget {
  const MyMenuPage({super.key});

  @override
  State<MyMenuPage> createState() => _MyMenuPageState();
}

class _MyMenuPageState extends State<MyMenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイメニュー'),
      ),
      body: const Center(
        child: Text('マイメニュー画面 - 実装予定'),
      ),
    );
  }
}