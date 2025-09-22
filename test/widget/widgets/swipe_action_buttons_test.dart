import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/swipe_action_buttons.dart';

void main() {
  group('SwipeActionButtons', () {
    testWidgets('「興味なし」と「行きたい」ボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      // 両方のボタンが表示される
      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('「興味なし」ボタンが正しく動作する', (WidgetTester tester) async {
      bool dislikePressed = false;
      bool likePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () => dislikePressed = true,
              onLike: () => likePressed = true,
            ),
          ),
        ),
      );

      // 興味なしボタンをタップ
      await tester.tap(find.byIcon(Icons.thumb_down));
      await tester.pump();

      expect(dislikePressed, isTrue);
      expect(likePressed, isFalse);
    });

    testWidgets('「行きたい」ボタンが正しく動作する', (WidgetTester tester) async {
      bool dislikePressed = false;
      bool likePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () => dislikePressed = true,
              onLike: () => likePressed = true,
            ),
          ),
        ),
      );

      // 行きたいボタンをタップ
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(likePressed, isTrue);
      expect(dislikePressed, isFalse);
    });

    testWidgets('無効状態でボタンが押せない', (WidgetTester tester) async {
      bool dislikePressed = false;
      bool likePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () => dislikePressed = true,
              onLike: () => likePressed = true,
              enabled: false,
            ),
          ),
        ),
      );

      // 無効状態でボタンをタップ
      await tester.tap(find.byIcon(Icons.thumb_down));
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(dislikePressed, isFalse);
      expect(likePressed, isFalse);
    });

    testWidgets('Material Design 3準拠のスタイリングが適用される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      // FloatingActionButtonが使用されている
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
    });

    testWidgets('アクセシビリティラベルが設定される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      // セマンティクスラベルが適切に設定されている
      expect(find.bySemanticsLabel('興味なし'), findsOneWidget);
      expect(find.bySemanticsLabel('行きたい'), findsOneWidget);
    });

    testWidgets('拡張されたアクセシビリティ機能が動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () {},
              onLike: () {},
              enabled: false, // 無効状態でのアクセシビリティテスト
            ),
          ),
        ),
      );

      // Semanticsウィジェットが存在する
      expect(find.byType(Semantics), findsAtLeastNWidgets(2));

      // 無効状態でもラベルは存在する
      expect(find.bySemanticsLabel('興味なし'), findsOneWidget);
      expect(find.bySemanticsLabel('行きたい'), findsOneWidget);
    });

    testWidgets('ハプティックフィードバック機能が動作する', (WidgetTester tester) async {
      bool dislikePressed = false;
      bool likePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () => dislikePressed = true,
              onLike: () => likePressed = true,
              enableHapticFeedback: true,
            ),
          ),
        ),
      );

      // ハプティックフィードバック有効時のボタン動作
      await tester.tap(find.byIcon(Icons.thumb_down));
      await tester.pump();
      expect(dislikePressed, isTrue);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      expect(likePressed, isTrue);
    });

    testWidgets('ハプティックフィードバック無効化が動作する', (WidgetTester tester) async {
      bool dislikePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () => dislikePressed = true,
              onLike: () {},
              enableHapticFeedback: false, // ハプティックフィードバック無効
            ),
          ),
        ),
      );

      // ハプティックフィードバック無効でもボタンは動作する
      await tester.tap(find.byIcon(Icons.thumb_down));
      await tester.pump();
      expect(dislikePressed, isTrue);
    });

    testWidgets('パフォーマンス最適化のRepaintBoundaryが適用される',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionButtons(
              onDislike: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      // RepaintBoundaryが複数存在する（各ボタン + 全体）
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(3));
    });
  });
}
