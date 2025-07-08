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
   GOOGLE_MAPS_API_KEY=あなたのGoogle_Maps_API_キー
3. アプリケーションを再起動

環境別設定の場合:
   DEV_HOTPEPPER_API_KEY=開発環境用キー
   STAGING_HOTPEPPER_API_KEY=ステージング環境用キー
   PROD_HOTPEPPER_API_KEY=本番環境用キー
   FLUTTER_ENV=development (または staging, production)

詳細については README.md#環境設定 を参照してください。
''';
  }
}
