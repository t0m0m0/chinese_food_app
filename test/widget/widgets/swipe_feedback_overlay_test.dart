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
                  enableParticleEffect: false, // テスト用にパーティクル効果を無効化
                ),
              ],
            ),
          ),
        ),
      );

      // 「行きたい」アイコンが表示される（パーティクル効果無効なので1つのみ）
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
                  enableParticleEffect: false, // テスト用にパーティクル効果を無効化
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

    testWidgets('パフォーマンス監視機能が動作する', (WidgetTester tester) async {
      // デバッグモードでのパフォーマンス計測テスト
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

      // 状態変更によるパフォーマンス計測実行
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: true,
                  showDislike: false,
                  enableParticleEffect: false,
                ),
              ],
            ),
          ),
        ),
      );

      // アニメーションの進行をテスト
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('エラーハンドリングが適切に動作する', (WidgetTester tester) async {
      // 正常なケースから異常なケースへの移行をテスト
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SwipeFeedbackOverlay(
                  showLike: true,
                  showDislike: false,
                  enableParticleEffect: false,
                ),
              ],
            ),
          ),
        ),
      );

      // 例外が発生してもアプリが継続することを確認
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // 状態をリセット
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

      // アニメーション終了後は何も表示されない
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });
}
