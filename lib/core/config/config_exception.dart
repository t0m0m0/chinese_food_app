/// 設定関連の例外
class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;

  @override
  String toString() {
    return '''
🚨 設定エラー: $message

修正方法:
1. プロジェクトルートに .env ファイルを作成
2. 以下の環境変数を追加:
   HOTPEPPER_API_KEY=あなたのHotPepper_API_キー
3. アプリケーションを再起動

詳細については README.md#環境設定 を参照してください。
''';
  }
}
