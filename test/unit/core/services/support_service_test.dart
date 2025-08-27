import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/core/services/support_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Mock生成のためのアノテーション
@GenerateMocks([])
class MockUrlLauncher extends Mock {
  Future<bool> launch(String url, {LaunchMode? mode}) async {
    return super.noSuchMethod(
      Invocation.method(#launch, [url], {#mode: mode}),
      returnValue: Future.value(true),
    );
  }
}

void main() {
  group('SupportService', () {
    late SupportService supportService;

    setUp(() {
      supportService = SupportService();
    });

    group('sendContactEmail', () {
      test('should validate inputs properly', () async {
        // Arrange
        const userEmail = 'test@example.com';
        const subject = 'テストの問い合わせ';
        const body = 'これはテスト内容です。';

        // Act - テスト環境では実際の送信はできないため、バリデーションのみテスト
        final result = await supportService.sendContactEmail(
          userEmail: userEmail,
          subject: subject,
          body: body,
        );

        // Assert - テスト環境では失敗するが、バリデーションエラーでないことを確認
        expect(result.isFailure, isTrue);
        expect(result.exceptionOrNull?.message, isNot(contains('メールアドレス')));
        expect(result.exceptionOrNull?.message, isNot(contains('件名')));
        expect(result.exceptionOrNull?.message, isNot(contains('お問い合わせ内容')));
      });

      test('should return failure when email launch fails', () async {
        // Arrange
        const subject = 'テストの問い合わせ';
        const body = 'これはテスト内容です。';

        // Act - 無効なメール形式でテスト
        final result = await supportService.sendContactEmail(
          userEmail: '',
          subject: subject,
          body: body,
        );

        // Assert
        expect(result.isFailure, isTrue);
      });

      test('should validate email format', () async {
        // Arrange
        const invalidEmail = 'invalid-email';
        const subject = 'テスト';
        const body = 'テスト内容';

        // Act
        final result = await supportService.sendContactEmail(
          userEmail: invalidEmail,
          subject: subject,
          body: body,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.exceptionOrNull?.message, contains('メールアドレス'));
      });

      test('should validate required fields', () async {
        // Act & Assert
        final result1 = await supportService.sendContactEmail(
          userEmail: 'test@example.com',
          subject: '',
          body: 'test body',
        );
        expect(result1.isFailure, isTrue);

        final result2 = await supportService.sendContactEmail(
          userEmail: 'test@example.com',
          subject: 'test subject',
          body: '',
        );
        expect(result2.isFailure, isTrue);
      });
    });

    group('getHelpSections', () {
      test('should return enabled help sections', () {
        // Act
        final sections = supportService.getHelpSections();

        // Assert
        expect(sections, isA<List<HelpSection>>());
        expect(sections.isNotEmpty, isTrue);
        expect(sections.any((section) => section.title == 'よくある質問'), isTrue);
        expect(sections.any((section) => section.title == '使い方ガイド'), isTrue);
        expect(sections.any((section) => section.title == 'お問い合わせ'), isTrue);
      });

      test('should return sections in correct order', () {
        // Act
        final sections = supportService.getHelpSections();

        // Assert
        expect(sections.first.title, equals('よくある質問'));
        expect(sections.last.title, equals('お問い合わせ'));
      });
    });

    group('getHelpContent', () {
      test('should return content for valid section id', () {
        // Act
        final content = supportService.getHelpContent('faq');

        // Assert
        expect(content, isNotNull);
        expect(content!.sections, isNotEmpty);
        expect(content.title, isNotEmpty);
      });

      test('should return null for invalid section id', () {
        // Act
        final content = supportService.getHelpContent('invalid-section');

        // Assert
        expect(content, isNull);
      });
    });

    group('getTroubleshootingSteps', () {
      test('should return troubleshooting steps for common issues', () {
        // Act
        final steps = supportService.getTroubleshootingSteps();

        // Assert
        expect(steps, isA<List<TroubleshootingStep>>());
        expect(steps.isNotEmpty, isTrue);
        expect(steps.any((step) => step.title.contains('位置情報')), isTrue);
        expect(steps.any((step) => step.title.contains('アプリ')), isTrue);
      });
    });

    group('reportBug', () {
      test('should validate bug report correctly', () async {
        // Arrange
        const bugReport = BugReport(
          title: 'アプリがクラッシュする',
          description: '検索ボタンを押すとアプリが落ちます',
          stepsToReproduce: ['検索画面を開く', '検索ボタンを押す'],
          userEmail: 'user@example.com',
          deviceInfo: 'iPhone 14, iOS 16.0',
        );

        // Act
        final result = await supportService.reportBug(bugReport);

        // Assert - テスト環境では失敗するが、バリデーションエラーでないことを確認
        expect(result.isFailure, isTrue);
        expect(result.exceptionOrNull?.message, isNot(contains('タイトル')));
        expect(result.exceptionOrNull?.message, isNot(contains('説明')));
        expect(result.exceptionOrNull?.message, isNot(contains('メールアドレス')));
      });

      test('should validate bug report fields', () async {
        // Arrange
        const invalidBugReport = BugReport(
          title: '',
          description: 'description',
          stepsToReproduce: [],
          userEmail: 'invalid-email',
          deviceInfo: 'device info',
        );

        // Act
        final result = await supportService.reportBug(invalidBugReport);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });
  });
}
