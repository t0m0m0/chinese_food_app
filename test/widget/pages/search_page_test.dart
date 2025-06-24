import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_food_app/presentation/pages/search/search_page.dart';

void main() {
  group('SearchPage', () {
    testWidgets('should display search form with location toggle', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(),
        ),
      );

      // then: 検索フォームが表示される（実装がないため失敗するはず）
      expect(find.text('現在地で検索'), findsOneWidget);
      expect(find.text('住所で検索'), findsOneWidget);
    });

    testWidgets('should display initial state message', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(),
        ),
      );

      // then: 初期状態のメッセージが表示される
      expect(find.text('検索ボタンを押して中華料理店を探しましょう'), findsOneWidget);
    });

    testWidgets('should display search button', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(),
        ),
      );

      // then: 検索ボタンが表示される
      expect(find.text('中華料理店を検索'), findsOneWidget);
    });

    testWidgets('should show no loading state initially', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(),
        ),
      );

      // then: 初期状態ではローディングが表示されない
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should have both radio buttons for location selection', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(),
        ),
      );

      // then: 両方のラジオボタンが存在する
      expect(find.byType(RadioListTile<bool>), findsNWidgets(2));
      
      // 現在地で検索がデフォルトで選択されている
      final currentLocationRadio = find.byWidgetPredicate(
        (Widget widget) => widget is RadioListTile<bool> && 
        widget.value == true && 
        widget.groupValue == true
      );
      expect(currentLocationRadio, findsOneWidget);
    });
  });
}