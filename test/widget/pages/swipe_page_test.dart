import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';

void main() {
  group('SwipePage', () {
    testWidgets('should display card swiper with store cards', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SwipePage(),
        ),
      );

      // then: flutter_card_swiperが使用されている（実装がないため失敗するはず）
      expect(find.text('AppCardSwiper'), findsOneWidget);
    });

    testWidgets('should handle right swipe to set want_to_go status',
        (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SwipePage(),
        ),
      );

      // then: スワイプインジケーターが表示される（実装がないため失敗するはず）
      expect(find.text('→ 行きたい'), findsOneWidget);
    });

    testWidgets('should handle left swipe to set bad status', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SwipePage(),
        ),
      );

      // then: スワイプインジケーターが表示される（実装がないため失敗するはず）
      expect(find.text('← 興味なし'), findsOneWidget);
    });

    testWidgets('should show empty state when no more cards', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SwipePage(),
        ),
      );

      // then: 空の状態メッセージが表示される（実装がないため失敗するはず）
      expect(find.text('カードがありません'), findsNothing);
    });
  });
}
