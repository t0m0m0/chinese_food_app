import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/photo_selection_dialog.dart';

void main() {
  group('PhotoSelectionDialog Widget Tests', () {
    testWidgets('ダイアログが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSelectionDialog.show(context),
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('写真を選択'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);
      expect(find.text('ギャラリーから選択'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('カスタムタイトルとサブタイトルが表示される', (WidgetTester tester) async {
      const customTitle = 'カスタムタイトル';
      const customSubtitle = 'カスタムサブタイトル';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSelectionDialog.show(
                  context,
                  title: customTitle,
                  subtitle: customSubtitle,
                ),
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text(customTitle), findsOneWidget);
      expect(find.text(customSubtitle), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSelectionDialog.show(context),
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoSelectionDialog), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoSelectionDialog), findsNothing);
    });

    testWidgets('UIコンポーネントが正しく配置されている', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSelectionDialog.show(context),
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // AlertDialogの構造を確認
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));

      // ボタンの順序を確認（カメラが先、ギャラリーが後）
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final firstTile = listTiles.first;
      final secondTile = listTiles.last;

      expect((firstTile.leading as Icon).icon, Icons.camera_alt);
      expect((secondTile.leading as Icon).icon, Icons.photo_library);
      expect((firstTile.title as Text).data, 'カメラで撮影');
      expect((secondTile.title as Text).data, 'ギャラリーから選択');
    });
  });
}
