/// 運用・サポート体制に関する設定クラス
/// Issue #144: 運用・サポート体制整備の設定値を管理
class OperationsConfig {
  // プライベートコンストラクタ（静的クラスとして使用）
  const OperationsConfig._();

  // サポート体制設定
  static const String supportEmail = 'support@machiapp.local';
  static const int supportResponseTimeHours = 24;

  // 監視・アラート設定
  static const double crashRateThreshold = 0.001; // 0.1%
  static const double appStoreRatingThreshold = 4.0;

  // KPI監視間隔設定
  static const int dailyAnalyticsUpdateHour = 9; // 9時
  static const int weeklyReportDayOfWeek = 1; // 月曜日 (1=月曜)

  // ヘルプ機能設定
  static const Map<String, bool> helpSectionsEnabled = {
    'faq': true,
    'tutorial': true,
    'contact': true,
    'troubleshooting': true,
    'userGuide': true,
  };

  // バリデーション関数

  /// メールアドレス形式の検証
  static bool isValidEmailFormat(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// クラッシュ率閾値の検証
  static bool isValidCrashRate(double rate) {
    return rate > 0.0 && rate <= 1.0;
  }

  /// アプリストア評価閾値の検証
  static bool isValidRatingThreshold(double rating) {
    return rating > 0.0 && rating <= 5.0;
  }

  /// デバッグ情報の取得
  static Map<String, dynamic> get debugInfo => {
        'supportEmail': supportEmail,
        'supportResponseTimeHours': supportResponseTimeHours,
        'crashRateThreshold': crashRateThreshold,
        'appStoreRatingThreshold': appStoreRatingThreshold,
        'dailyAnalyticsUpdateHour': dailyAnalyticsUpdateHour,
        'weeklyReportDayOfWeek': weeklyReportDayOfWeek,
        'helpSectionsEnabled': helpSectionsEnabled,
        'configValidation': {
          'supportEmailValid': isValidEmailFormat(supportEmail),
          'crashRateValid': isValidCrashRate(crashRateThreshold),
          'ratingThresholdValid':
              isValidRatingThreshold(appStoreRatingThreshold),
        },
      };
}
