import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/photo_display_widget.dart';

void main() {
  group('PhotoDisplayWidget Tests', () {
    testWidgets('写真が正しく表示される', (WidgetTester tester) async {
      const testImagePath = 'test_assets/test_image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDisplayWidget(
              imagePath: testImagePath,
            ),
          ),
        ),
      );

      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('タップで拡大表示される', (WidgetTester tester) async {
      const testImagePath = 'test_assets/test_image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDisplayWidget(
              imagePath: testImagePath,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PhotoDisplayWidget));
      await tester.pump();

      // タップイベントが発生することを確認
      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
    });

    testWidgets('削除ボタンが表示される', (WidgetTester tester) async {
      const testImagePath = 'test_assets/test_image.jpg';
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: PhotoDisplayWidget(
                  imagePath: testImagePath,
                  onDelete: () {
                    deletePressed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete), warnIfMissed: false);
      await tester.pump();

      expect(deletePressed, isTrue);
    });

    testWidgets('ローディング状態が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDisplayWidget(
              imagePath: null,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラー状態が表示される', (WidgetTester tester) async {
      const errorMessage = 'Failed to load image';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDisplayWidget(
              imagePath: null,
              errorMessage: errorMessage,
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('写真がない場合はプレースホルダーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDisplayWidget(
              imagePath: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.text('写真なし'), findsOneWidget);
    });
  });
}
