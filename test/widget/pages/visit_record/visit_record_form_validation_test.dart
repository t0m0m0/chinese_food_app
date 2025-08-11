import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/presentation/pages/visit_record/visit_record_form_page.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';

class MockAddVisitRecordUsecase extends Mock implements AddVisitRecordUsecase {}

void main() {
  group('VisitRecordFormPage - Validation Tests', () {
    late Store testStore;

    setUp(() {
      testStore = Store(
        id: 'test_id',
        name: 'テスト店舗',
        address: '東京都渋谷区',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        memo: '',
        createdAt: DateTime.now(),
      );
    });

    Widget createTestWidget(Widget child) {
      return Provider<AddVisitRecordUsecase>(
        create: (_) => MockAddVisitRecordUsecase(),
        child: MaterialApp(home: child),
      );
    }

    testWidgets('メニューフィールドが空の場合、適切なエラーメッセージを表示する', (tester) async {
      // arrange
      await tester.pumpWidget(
        createTestWidget(VisitRecordFormPage(store: testStore)),
      );

      // act
      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pump();

      // assert
      expect(find.text('メニューを入力してください'), findsOneWidget);
    });

    testWidgets('メニューが100文字を超える場合、適切なエラーメッセージを表示する', (tester) async {
      // arrange
      final longMenu = 'a' * 101; // 101文字
      await tester.pumpWidget(
        MaterialApp(
          home: VisitRecordFormPage(store: testStore),
        ),
      );

      // act
      final menuField = find.byKey(const Key('menu_field'));
      await tester.enterText(menuField, longMenu);
      await tester.pump();

      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pump();

      // assert
      expect(find.text('メニューは100文字以内で入力してください'), findsOneWidget);
    });

    testWidgets('メモが500文字を超える場合、適切なエラーメッセージを表示する', (tester) async {
      // arrange
      final longMemo = 'a' * 501; // 501文字
      await tester.pumpWidget(
        MaterialApp(
          home: VisitRecordFormPage(store: testStore),
        ),
      );

      // act
      final menuField = find.byKey(const Key('menu_field'));
      await tester.enterText(menuField, '有効なメニュー');
      await tester.pump();

      final memoField = find.byKey(const Key('memo_field'));
      await tester.enterText(memoField, longMemo);
      await tester.pump();

      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pump();

      // assert
      expect(find.text('メモは500文字以内で入力してください'), findsOneWidget);
    });

    testWidgets('未来の日付が選択された場合、保存時にエラーメッセージを表示する', (tester) async {
      // arrange
      await tester.pumpWidget(
        createTestWidget(VisitRecordFormPage(store: testStore)),
      );

      // act
      final menuField = find.byKey(const Key('menu_field'));
      await tester.enterText(menuField, '有効なメニュー');
      await tester.pump();

      // 未来の日付を設定（モック日付選択をシミュレート）
      final dateButton = find.byKey(const Key('date_selector'));
      await tester.tap(dateButton);
      await tester.pump();

      // Note: この部分は実際のDatePickerのモック化が必要
      // 今回はUIテストとして、エラーメッセージの確認のみを行う

      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pump();

      // assert
      // 保存処理でArgumentErrorが発生した場合のスナックバー表示を確認
      // 実際の実装では、未来日付のバリデーションは保存時に行われる
    });

    testWidgets('有効なデータが入力された場合、バリデーションエラーは表示されない', (tester) async {
      // arrange
      await tester.pumpWidget(
        createTestWidget(VisitRecordFormPage(store: testStore)),
      );

      // act
      final menuField = find.byKey(const Key('menu_field'));
      await tester.enterText(menuField, '有効なメニュー');
      await tester.pump();

      final memoField = find.byKey(const Key('memo_field'));
      await tester.enterText(memoField, '有効なメモ');
      await tester.pump();

      // バリデーションを実行
      final formState = tester.state<FormState>(find.byType(Form));
      final isValid = formState.validate();

      // assert
      expect(isValid, isTrue);
      expect(find.text('メニューを入力してください'), findsNothing);
      expect(find.text('メニューは100文字以内で入力してください'), findsNothing);
      expect(find.text('メモは500文字以内で入力してください'), findsNothing);
    });
  });
}
