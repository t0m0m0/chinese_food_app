// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_food_app/main.dart';

void main() {
  testWidgets('町中華アプリの基本構造テスト', (WidgetTester tester) async {
    // アプリをビルドしてフレームをトリガー
    await tester.pumpWidget(const MyApp());

    // BottomNavigationBarが表示されることを確認
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // 3つのタブが存在することを確認（BottomNavigationBar内で検索）
    expect(
        find.descendant(
            of: find.byType(BottomNavigationBar), matching: find.text('スワイプ')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(BottomNavigationBar), matching: find.text('検索')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text('マイメニュー')),
        findsOneWidget);

    // デフォルトでスワイプページが表示されることを確認（実装済み）
    expect(find.text('← 興味なし'), findsOneWidget);
    expect(find.text('→ 行きたい'), findsOneWidget);

    // 検索タブをタップして画面遷移をテスト
    await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar), matching: find.text('検索')));
    await tester.pump();

    // 検索ページが表示されることを確認（実装済みUI）
    expect(find.text('現在地で検索'), findsOneWidget);
    expect(find.text('中華料理店を検索'), findsOneWidget);

    // マイメニュータブをタップして画面遷移をテスト
    await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar), matching: find.text('マイメニュー')));
    await tester.pump();

    // マイメニューページが表示されることを確認（実装済み）
    expect(find.text('行きたい'), findsOneWidget);
    expect(find.text('行った'), findsOneWidget);
    expect(find.text('興味なし'), findsOneWidget);
  });
}
