# 本番環境セットアップガイド

中華料理アプリ「マチアプ」の本番環境向け設定手順

## 📋 概要

このガイドでは、本番環境でのアプリケーション実行に必要な設定を説明します。

## 🔑 必要なAPIキー

### HotPepper グルメサーチAPI（必須）

本番環境では、リクルート社のHotPepper APIキーが必要です。

#### 取得手順
1. [リクルート Webサービス](https://webservice.recruit.co.jp/register/) にアクセス
2. アカウント作成・ログイン
3. 本番用アプリケーションを新規登録
4. 利用規約・制限事項を確認：
   - 1日3,000リクエスト制限
   - 1秒間5リクエスト制限  
   - データキャッシュ禁止
5. 本番用APIキーを取得

## ⚙️ 環境設定

### 1. 環境変数設定ファイル作成

```bash
# .env.production.example をベースに作成
cp .env.production.example .env.production
```

### 2. APIキー設定

`.env.production` ファイルを編集：

```bash
# 本番環境設定
FLUTTER_ENV=production

# HotPepper グルメサーチAPI（本番用）
HOTPEPPER_API_KEY=your_production_hotpepper_api_key_here
```

### 3. APIキー要件

本番環境のAPIキーは以下の要件を満たす必要があります：

- **最低16文字以上**
- **英数字のみ** (a-z, A-Z, 0-9)
- **特殊文字・記号は不可**（ハイフン、アンダースコア、スペース等）

#### ✅ 有効なAPIキーの例
```
validproductionkey123456789
PRODUCTIONKEY1234567890
MixedCaseApiKey123456789
```

#### ❌ 無効なAPIキーの例
```
short123                    # 16文字未満
api-key-with-hyphens       # ハイフン含む
api_key_with_underscores   # アンダースコア含む
apikey with spaces         # スペース含む
apikey123!@#              # 特殊文字含む
```

## 🏗️ ビルド・デプロイ

### Android

```bash
# 本番用APKビルド
flutter build apk --dart-define=FLUTTER_ENV=production

# App Bundle（Play Store推奨）
flutter build appbundle --dart-define=FLUTTER_ENV=production

# 難読化付きリリース
flutter build appbundle \
  --obfuscate \
  --split-debug-info=build/debug \
  --dart-define=FLUTTER_ENV=production
```

### iOS

```bash
# 本番用iOSビルド
flutter build ios --dart-define=FLUTTER_ENV=production
```

### Web

```bash  
# 本番用Webビルド
flutter build web --dart-define=FLUTTER_ENV=production
```

## 🔒 セキュリティ設定

### APIキー保護

- **環境変数での管理**: `.env.production` ファイルはGit追跡対象外
- **CI/CD環境**: 環境変数で直接設定することを推奨
- **機密情報の分離**: 開発用キーと本番用キーを必ず分けて管理

### 設定検証

アプリケーション起動時に自動で以下を検証：

- APIキーの存在確認
- APIキー形式の妥当性
- 本番環境固有の設定チェック

## 📊 監視・運用

### ログレベル設定

本番環境では適切なログレベルが自動設定されます：

- デバッグ情報は非出力
- エラーログのみ出力
- パフォーマンス最適化

### 使用量監視

HotPepper APIの制限監視：

- リクエスト数のトラッキング
- レート制限の遵守
- エラー率の監視

## 🐛 トラブルシューティング

### APIキー設定エラー

**症状**: 「APIキーが設定されていません」エラー

**解決方法**:
1. `.env.production` ファイルの存在確認
2. `HOTPEPPER_API_KEY` の設定確認
3. APIキーの形式確認（16文字以上、英数字のみ）

### API通信エラー

**症状**: 「401 Unauthorized」または「429 Too Many Requests」

**解決方法**:
1. 本番用APIキーの有効性確認
2. API利用制限の確認
3. リクエスト頻度の調整

### ビルドエラー

**症状**: ビルド時の設定エラー

**解決方法**:
1. `--dart-define=FLUTTER_ENV=production` の指定確認
2. 依存関係の更新: `flutter pub get`
3. クリーンビルド: `flutter clean && flutter pub get`

## ⚠️ 注意事項

### 利用規約遵守

- **HotPepper API**: データキャッシュ禁止
- **利用制限**: 1日3,000リクエスト、1秒間5リクエストを超過しないこと
- **Attribution**: 適切なデータソース表記

### セキュリティ

- 本番用APIキーの機密管理を徹底
- `.env.production` ファイルは絶対にコミットしない
- CI/CD環境では環境変数での設定を推奨

## 📝 チェックリスト

デプロイ前の確認事項：

- [ ] 本番用HotPepper APIキーを取得済み
- [ ] `.env.production` ファイルを作成・設定済み
- [ ] APIキー形式の妥当性を確認済み
- [ ] ビルドが正常に完了することを確認済み
- [ ] セキュリティ設定が適切に適用されることを確認済み
- [ ] 利用規約・制限事項を理解・遵守済み

## 🔗 関連資料

- [HotPepper API ドキュメント](https://webservice.recruit.co.jp/doc/hotpepper/)
- [Flutter Production デプロイメント](https://docs.flutter.dev/deployment)
- [アプリストア配布ガイド](docs/STORE_ASSETS_GUIDE.md)