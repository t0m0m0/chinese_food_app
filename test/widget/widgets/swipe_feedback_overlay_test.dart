import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/swipe_feedback_overlay.dart';

void main() {
  group('SwipeFeedbackOverlay', () {
    testWidgets('右スワイプで「行きたい」アニメーションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: true,
                  showDislike: false,
                ),
              ],
            ),
          ),
        ),
      );

      // 「行きたい」アイコンが表示される
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('行きたい'), findsOneWidget);

      // 「興味なし」アイコンは表示されない
      expect(find.byIcon(Icons.thumb_down), findsNothing);
      expect(find.text('興味なし'), findsNothing);
    });

    testWidgets('左スワイプで「興味なし」アニメーションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: false,
                  showDislike: true,
                ),
              ],
            ),
          ),
        ),
      );

      // 「興味なし」アイコンが表示される
      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.text('興味なし'), findsOneWidget);

      // 「行きたい」アイコンは表示されない
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.text('行きたい'), findsNothing);
    });

    testWidgets('何も表示されない状態', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: false,
                  showDislike: false,
                ),
              ],
            ),
          ),
        ),
      );

      // 何も表示されない
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byIcon(Icons.thumb_down), findsNothing);
      expect(find.text('行きたい'), findsNothing);
      expect(find.text('興味なし'), findsNothing);
    });

    testWidgets('アニメーション効果が適用される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: true,
                  showDislike: false,
                ),
              ],
            ),
          ),
        ),
      );

      // ScaleTransitionが存在する
      expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));

      // FadeTransitionが存在する
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    });
  });
}
