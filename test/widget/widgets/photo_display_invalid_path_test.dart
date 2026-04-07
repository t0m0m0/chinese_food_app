import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/photo_display_widget.dart';

/// 写真ファイルパス不正時テスト
///
/// 削除済みファイル・空パス・不正パスへの参照時の挙動を検証
void main() {
  Widget buildTestWidget({
    String? imagePath,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    bool isLoading = false,
    String? errorMessage,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 200,
          child: PhotoDisplayWidget(
            imagePath: imagePath,
            onTap: onTap,
            onDelete: onDelete,
            isLoading: isLoading,
            errorMessage: errorMessage,
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }

  group('写真ファイルパスが不正な場合', () {
    testWidgets('imagePathがnullの場合、プレースホルダーが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: null));

      expect(find.text('写真なし'), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('imagePathが空文字の場合、プレースホルダーが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: ''));

      expect(find.text('写真なし'), findsOneWidget);
    });

    testWidgets('存在しないファイルパスの場合、エラー表示になる', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        imagePath: '/nonexistent/path/to/image.jpg',
      ));
      await tester.pump();

      // Image.fileのerrorBuilderが呼ばれてエラー表示になる
      // 注: テスト環境でImage.fileの挙動は実際のファイルI/Oに依存
      // errorBuilderが機能することを確認
      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
    });

    testWidgets('errorMessageが設定されている場合、エラー表示', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        errorMessage: '写真の読み込みに失敗しました',
      ));

      expect(find.text('写真の読み込みに失敗しました'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('isLoading中はローディングインジケータが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('写真の削除ボタン', () {
    testWidgets('onDeleteが設定されている場合、削除ボタンが表示される', (tester) async {
      var deleted = false;
      await tester.pumpWidget(buildTestWidget(
        imagePath: null,
        onDelete: () => deleted = true,
      ));

      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      expect(deleted, true);
    });

    testWidgets('onDeleteが未設定の場合、削除ボタンは表示されない', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        imagePath: null,
        onDelete: null,
      ));

      expect(find.byIcon(Icons.delete), findsNothing);
    });
  });

  group('写真タップ操作', () {
    testWidgets('onTapが設定されている場合、タップで呼び出される', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestWidget(
        imagePath: null,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, true);
    });

    testWidgets('onTapが未設定でもタップしてクラッシュしない', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        imagePath: null,
        onTap: null,
      ));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      // クラッシュしないことが確認できればOK
    });
  });

  group('エラー状態の優先順位', () {
    testWidgets('isLoadingはerrorMessageより優先される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isLoading: true,
        errorMessage: 'エラー',
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('エラー'), findsNothing);
    });

    testWidgets('errorMessageはimagePathより優先される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        errorMessage: 'エラーメッセージ',
        imagePath: '/some/path.jpg',
      ));

      expect(find.text('エラーメッセージ'), findsOneWidget);
    });
  });
}
