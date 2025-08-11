import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/utils/error_message_helper.dart';

void main() {
  group('ErrorMessageHelper - Visit Record Error Messages', () {
    group('getVisitRecordErrorMessage', () {
      test('メニューが空文字の場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'menu_empty';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, 'メニューを入力してください。');
      });

      test('メニューの文字数制限超過の場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'menu_length_exceeded';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, 'メニューは100文字以内で入力してください。');
      });

      test('メモの文字数制限超過の場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'memo_length_exceeded';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, 'メモは500文字以内で入力してください。');
      });

      test('未来日付の場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'future_date';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, '訪問日時は未来の日付にできません。');
      });

      test('店舗が見つからない場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'store_not_found';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, '対象の店舗が見つかりません。');
      });

      test('重複する記録の場合、適切なメッセージを返す', () {
        // arrange
        const errorType = 'duplicate_record';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, 'この訪問記録は既に存在します。');
      });

      test('不明なエラータイプの場合、デフォルトメッセージを返す', () {
        // arrange
        const errorType = 'unknown_error';

        // act
        final result = ErrorMessageHelper.getVisitRecordErrorMessage(errorType);

        // assert
        expect(result, 'データの保存に失敗しました。しばらくしてから再試行してください。');
      });
    });

    group('getVisitRecordErrorFromException', () {
      test('ArgumentError with menu empty message', () {
        // arrange
        final exception = ArgumentError('Menu cannot be empty');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, 'メニューを入力してください。');
      });

      test('ArgumentError with menu length exceeded message', () {
        // arrange
        final exception = ArgumentError(
            'Menu must be 100 characters or less: 150 characters');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, 'メニューは100文字以内で入力してください。');
      });

      test('ArgumentError with memo length exceeded message', () {
        // arrange
        final exception = ArgumentError(
            'Memo must be 500 characters or less: 600 characters');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, 'メモは500文字以内で入力してください。');
      });

      test('ArgumentError with future date message', () {
        // arrange
        final exception =
            ArgumentError('Visited date cannot be in the future: 2025-12-31');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, '訪問日時は未来の日付にできません。');
      });

      test('Foreign Key constraint error', () {
        // arrange
        final exception =
            Exception('SqliteException(787): FOREIGN KEY constraint failed');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, '対象の店舗が見つかりません。');
      });

      test('UNIQUE constraint error', () {
        // arrange
        final exception =
            Exception('SqliteException(2067): UNIQUE constraint failed');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, 'この訪問記録は既に存在します。');
      });

      test('Other general exception', () {
        // arrange
        final exception = Exception('Some other database error');

        // act
        final result =
            ErrorMessageHelper.getVisitRecordErrorFromException(exception);

        // assert
        expect(result, 'データの保存に失敗しました。しばらくしてから再試行してください。');
      });
    });
  });
}
