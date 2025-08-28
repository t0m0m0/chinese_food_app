import 'package:url_launcher/url_launcher.dart';
import '../config/operations_config.dart';
import '../types/result.dart';
import '../exceptions/base_exception.dart';

/// サポート・ヘルプ機能を提供するサービスクラス
/// Issue #144: 運用・サポート体制整備の一環として実装
class SupportService {
  /// お問い合わせメールを送信する
  Future<Result<void>> sendContactEmail({
    required String userEmail,
    required String subject,
    required String body,
  }) async {
    try {
      // バリデーション
      if (userEmail.isEmpty ||
          !OperationsConfig.isValidEmailFormat(userEmail)) {
        return Failure(BaseException('有効なメールアドレスを入力してください。'));
      }

      if (subject.trim().isEmpty) {
        return Failure(BaseException('件名を入力してください。'));
      }

      if (body.trim().isEmpty) {
        return Failure(BaseException('お問い合わせ内容を入力してください。'));
      }

      // メールURL作成
      final emailUrl = _createEmailUrl(
        to: OperationsConfig.supportEmail,
        subject: subject,
        body: _createEmailBody(userEmail, body),
      );

      // メールアプリ起動
      final uri = Uri.parse(emailUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        return Failure(BaseException(
            'メールアプリを起動できませんでした。デバイスにメールアプリがインストールされていることを確認してください。'));
      }

      return const Success(null);
    } catch (e) {
      return Failure(BaseException('お問い合わせの送信中にエラーが発生しました: $e'));
    }
  }

  /// ヘルプセクション一覧を取得
  List<HelpSection> getHelpSections() {
    final sections = <HelpSection>[];

    if (OperationsConfig.helpSectionsEnabled['faq'] == true) {
      sections.add(const HelpSection(
        id: 'faq',
        title: 'よくある質問',
        icon: 'help_outline',
        description: '多く寄せられる質問と回答',
      ));
    }

    if (OperationsConfig.helpSectionsEnabled['tutorial'] == true) {
      sections.add(const HelpSection(
        id: 'tutorial',
        title: '使い方ガイド',
        icon: 'school',
        description: 'アプリの基本的な使い方',
      ));
    }

    if (OperationsConfig.helpSectionsEnabled['troubleshooting'] == true) {
      sections.add(const HelpSection(
        id: 'troubleshooting',
        title: 'トラブルシューティング',
        icon: 'build',
        description: '問題解決のガイド',
      ));
    }

    if (OperationsConfig.helpSectionsEnabled['userGuide'] == true) {
      sections.add(const HelpSection(
        id: 'user_guide',
        title: '機能説明',
        icon: 'info',
        description: '各機能の詳細説明',
      ));
    }

    if (OperationsConfig.helpSectionsEnabled['contact'] == true) {
      sections.add(const HelpSection(
        id: 'contact',
        title: 'お問い合わせ',
        icon: 'mail',
        description: 'サポートへのお問い合わせ',
      ));
    }

    return sections;
  }

  /// 指定されたセクションのヘルプコンテンツを取得
  HelpContent? getHelpContent(String sectionId) {
    switch (sectionId) {
      case 'faq':
        return _getFaqContent();
      case 'tutorial':
        return _getTutorialContent();
      case 'troubleshooting':
        return _getTroubleshootingContent();
      case 'user_guide':
        return _getUserGuideContent();
      case 'contact':
        return _getContactContent();
      default:
        return null;
    }
  }

  /// トラブルシューティング手順を取得
  List<TroubleshootingStep> getTroubleshootingSteps() {
    return [
      const TroubleshootingStep(
        title: '位置情報が取得できない',
        steps: [
          '設定 > プライバシー > 位置情報サービス でオンになっているか確認',
          'アプリの位置情報許可を「使用中のみ許可」に設定',
          'デバイスを再起動してから再度お試しください',
        ],
        category: 'location',
      ),
      const TroubleshootingStep(
        title: 'アプリが起動しない・クラッシュする',
        steps: [
          'アプリを完全に終了して再起動',
          'デバイスの空き容量を確認（最低1GB以上推奨）',
          'アプリを最新版にアップデート',
          'デバイスを再起動してから再度お試しください',
        ],
        category: 'app_crash',
      ),
      const TroubleshootingStep(
        title: '店舗情報が表示されない',
        steps: [
          'インターネット接続を確認',
          '位置情報の許可を確認',
          'アプリを一度終了して再起動',
          '時間をおいてから再度お試しください',
        ],
        category: 'data_loading',
      ),
    ];
  }

  /// バグレポートを送信
  Future<Result<void>> reportBug(BugReport bugReport) async {
    try {
      // バリデーション
      if (bugReport.title.trim().isEmpty) {
        return Failure(BaseException('バグのタイトルを入力してください。'));
      }

      if (bugReport.title.length > 100) {
        return Failure(BaseException('バグのタイトルは100文字以内で入力してください。'));
      }

      if (bugReport.description.trim().isEmpty) {
        return Failure(BaseException('バグの説明を入力してください。'));
      }

      if (bugReport.description.length > 2000) {
        return Failure(BaseException('バグの説明は2000文字以内で入力してください。'));
      }

      if (!OperationsConfig.isValidEmailFormat(bugReport.userEmail)) {
        return Failure(BaseException('有効なメールアドレスを入力してください。'));
      }

      // バグレポートのメール本文を作成
      final subject = '[バグレポート] ${bugReport.title}';
      final body = _createBugReportBody(bugReport);

      return await sendContactEmail(
        userEmail: bugReport.userEmail,
        subject: subject,
        body: body,
      );
    } catch (e) {
      return Failure(BaseException('バグレポートの送信中にエラーが発生しました: $e'));
    }
  }

  // プライベートメソッド

  String _createEmailUrl({
    required String to,
    required String subject,
    required String body,
  }) {
    final encodedTo = Uri.encodeComponent(to);
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);

    return 'mailto:$encodedTo?subject=$encodedSubject&body=$encodedBody';
  }

  String _createEmailBody(String userEmail, String userBody) {
    return '''
お問い合わせ内容:
$userBody

---
送信者: $userEmail
送信日時: ${DateTime.now().toIso8601String()}
アプリ: マチアプ
''';
  }

  String _createBugReportBody(BugReport bugReport) {
    final stepsText = bugReport.stepsToReproduce
        .asMap()
        .entries
        .map((entry) => '  ${entry.key + 1}. ${entry.value}')
        .join('\n');

    final reportId =
        'BUG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return '''
【バグレポート】
レポートID: $reportId

■ 問題の概要
${bugReport.title}

■ 詳細な説明
${bugReport.description}

■ 再現手順
$stepsText

■ デバイス情報
${bugReport.deviceInfo}

■ 発生頻度
${bugReport.frequency ?? '未設定'}

■ うまの情報
${bugReport.additionalInfo ?? '特になし'}

■ 優先度
${_determineBugPriority(bugReport)}

---
報告者: ${bugReport.userEmail}
報告日時: ${DateTime.now().toIso8601String()}
アプリバージョン: 1.0.0+1
''';
  }

  HelpContent _getFaqContent() {
    return const HelpContent(
      title: 'よくある質問',
      sections: [
        HelpContentSection(
          title: 'アプリの基本的な使い方',
          items: [
            'Q: スワイプ機能はどう使いますか？\nA: 店舗カードを右にスワイプで「行きたい」、左にスワイプで「興味なし」になります。',
            'Q: 訪問記録はどうやって追加しますか？\nA: 「行った」店舗の詳細画面から「訪問記録を追加」ボタンを押してください。',
          ],
        ),
        HelpContentSection(
          title: '位置情報・検索関連',
          items: [
            'Q: 位置情報の許可は必要ですか？\nA: 近くの店舗検索に必要です。設定から許可してください。',
            'Q: 検索結果が表示されません\nA: インターネット接続と位置情報の許可を確認してください。',
          ],
        ),
      ],
    );
  }

  HelpContent _getTutorialContent() {
    return const HelpContent(
      title: '使い方ガイド',
      sections: [
        HelpContentSection(
          title: 'はじめに',
          items: [
            'マチアプは、町中華を探索・記録するためのアプリです。',
            'スワイプ操作で気になる店舗を「行きたい」リストに追加できます。',
            '実際に訪問した店舗の記録を写真付きで残すことができます。',
          ],
        ),
        HelpContentSection(
          title: '基本的な流れ',
          items: [
            '1. スワイプ画面で店舗を探索',
            '2. 気になる店舗を右スワイプ',
            '3. 検索画面で条件を絞って探索',
            '4. 実際に訪問したらマイメニューから記録追加',
          ],
        ),
      ],
    );
  }

  HelpContent _getTroubleshootingContent() {
    return const HelpContent(
      title: 'トラブルシューティング',
      sections: [
        HelpContentSection(
          title: '一般的な問題',
          items: [
            'アプリが起動しない場合は、デバイスの再起動をお試しください。',
            '位置情報が取得できない場合は、設定で位置情報の許可を確認してください。',
            'データが表示されない場合は、インターネット接続を確認してください。',
          ],
        ),
      ],
    );
  }

  HelpContent _getUserGuideContent() {
    return const HelpContent(
      title: '機能説明',
      sections: [
        HelpContentSection(
          title: 'スワイプ機能',
          items: [
            '右スワイプ: 行きたい店舗として保存',
            '左スワイプ: 興味なしとしてスキップ',
            '店舗カードタップ: 詳細情報を表示',
          ],
        ),
        HelpContentSection(
          title: 'マイメニュー',
          items: [
            '行きたい: スワイプで保存した店舗一覧',
            '行った: 訪問記録がある店舗一覧',
            '各店舗の詳細情報・写真・メモを確認',
          ],
        ),
      ],
    );
  }

  HelpContent _getContactContent() {
    return const HelpContent(
      title: 'お問い合わせ',
      sections: [
        HelpContentSection(
          title: 'サポートについて',
          items: [
            'サポートメール: ${OperationsConfig.supportEmail}',
            '対応時間: ${OperationsConfig.supportResponseTimeHours}時間以内',
            'お問い合わせの際は、使用デバイスとアプリバージョンをお知らせください。',
          ],
        ),
        HelpContentSection(
          title: 'サポートガイドライン',
          items: [
            'バグ報告は再現手順を明確に記載してください',
            '機能提案は具体的な使用ケースを含めてください',
            '緊急性の高い問題は件名に【緊急】を付けてください',
          ],
        ),
      ],
    );
  }

  /// バグの優先度を判定
  String _determineBugPriority(BugReport bugReport) {
    final title = bugReport.title.toLowerCase();
    final description = bugReport.description.toLowerCase();

    if (title.contains('クラッシュ') ||
        title.contains('起動しない') ||
        description.contains('アプリが落ちる')) {
      return '高（Critical）';
    } else if (title.contains('データ') ||
        title.contains('表示されない') ||
        description.contains('機能が使えない')) {
      return '中（High）';
    } else {
      return '低（Medium）';
    }
  }
}

// データクラス定義

class HelpSection {
  final String id;
  final String title;
  final String icon;
  final String description;

  const HelpSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });
}

class HelpContent {
  final String title;
  final List<HelpContentSection> sections;

  const HelpContent({
    required this.title,
    required this.sections,
  });
}

class HelpContentSection {
  final String title;
  final List<String> items;

  const HelpContentSection({
    required this.title,
    required this.items,
  });
}

class TroubleshootingStep {
  final String title;
  final List<String> steps;
  final String category;

  const TroubleshootingStep({
    required this.title,
    required this.steps,
    required this.category,
  });
}

class BugReport {
  final String title;
  final String description;
  final List<String> stepsToReproduce;
  final String userEmail;
  final String deviceInfo;
  final String? frequency;
  final String? additionalInfo;

  const BugReport({
    required this.title,
    required this.description,
    required this.stepsToReproduce,
    required this.userEmail,
    required this.deviceInfo,
    this.frequency,
    this.additionalInfo,
  });
}
