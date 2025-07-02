import 'package:flutter/material.dart';
import '../../../domain/entities/store.dart';

class StoreDetailPage extends StatelessWidget {
  const StoreDetailPage({
    super.key,
    required this.store,
  });

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗詳細'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name),
            Text(store.address),
            if (store.memo?.isNotEmpty == true) Text(store.memo!),
            const SizedBox(height: 16),
            const Text('行きたい'),
            const Text('行った'),
            const Text('興味なし'),
          ],
        ),
      ),
    );
  }
}