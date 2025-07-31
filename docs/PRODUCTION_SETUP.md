# 本番環境セットアップガイド

町中華探索アプリ「マチアプ」の本番環境セットアップ手順書

## 📋 概要

このガイドでは、開発環境から本番環境への移行とデプロイ手順を説明します。

## 🏗️ 環境構成

### 開発環境 (Development)
- **用途**: ローカル開発・テスト
- **APIキー管理**: `.env`ファイル
- **データベース**: ローカルSQLite
- **ログレベル**: DEBUG
- **デバッグ**: 有効

### ステージング環境 (Staging)  
- **用途**: 本番前テスト・QA
- **APIキー管理**: 環境変数
- **データベース**: テスト用SQLite
- **ログレベル**: DEBUG
- **デバッグ**: 有効

### 本番環境 (Production)
- **用途**: エンドユーザー向けリリース
- **APIキー管理**: Flutter Secure Storage
- **データベース**: 本番SQLite (暗号化)
- **ログレベル**: INFO
- **デバッグ**: 無効

## 🚀 本番デプロイ手順

### 1. 事前準備

#### 1.1 開発環境の確認
```bash
# Flutter環境確認
flutter doctor

# プロジェクトクリーンアップ
flutter clean
flutter pub get
```

#### 1.2 本番環境準備チェック
```bash
# 総合チェック実行
./scripts/check-production-ready.sh
```

このスクリプトでチェックされる項目：
- ✅ 開発環境の準備状況
- ✅ プロジェクト構成の完整性
- ✅ コード品質（フォーマット・静的解析）
- ✅ テスト合格状況
- ✅ セキュリティ（機密情報の漏洩チェック）
- ✅ 依存関係の状態
- ✅ ビルド可能性
- ✅ 設定ファイルの整合性

### 2. APIキー設定

#### 2.1 本番用APIキー準備
以下のAPIキーを取得してください：

**HotPepper Gourmet API**
- 取得先: [リクルートWebサービス](https://webservice.recruit.co.jp/)
- 制限: 1日3,000リクエスト、1秒間5リクエスト
- 形式: 英数字32〜50文字

**Google Maps API**
- 取得先: [Google Cloud Console](https://console.cloud.google.com/)
- 必要なAPI: Maps SDK for Android/iOS, Geocoding API
- 形式: `AIzaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

#### 2.2 本番環境でのAPIキー設定
```bash
# 本番環境でAPIキーを安全に設定
./scripts/setup-production-keys.sh
```

このスクリプトの機能：
- 📝 対話形式でAPIキー入力
- 🔍 APIキー形式の検証
- 🔐 Flutter Secure Storageへの暗号化保存
- ✅ 保存確認と検証

### 3. プラットフォーム別デプロイ

#### 3.1 iOS本番デプロイ

**前提条件**
- Apple Developer Program登録
- Xcode最新版
- 証明書とプロビジョニングプロファイル

**デプロイ手順**
```bash
# iOS本番ビルド実行
./scripts/deploy-production.sh ios
```

**手動作業**
1. Xcode Organizerを開く
2. 生成されたアーカイブを選択
3. App Store Connectにアップロード
4. App Store Connectでリリース設定

#### 3.2 Android本番デプロイ

**前提条件**
- Google Play Console登録
- 署名キーの準備

**署名キー設定**
```bash
# 環境変数設定
export ANDROID_KEYSTORE_PATH="/path/to/keystore.jks"
export ANDROID_KEY_ALIAS="your_key_alias"
export ANDROID_KEYSTORE_PASSWORD="keystore_password"
export ANDROID_KEY_PASSWORD="key_password"
```

**デプロイ手順**
```bash
# Android本番ビルド実行
./scripts/deploy-production.sh android
```

**手動作業**
1. Google Play Consoleにログイン
2. アプリを選択し「リリース」→「本番環境」
3. 生成されたApp Bundleをアップロード

#### 3.3 Web本番デプロイ

**デプロイ手順**
```bash
# Web本番ビルド実行
./scripts/deploy-production.sh web
```

**手動作業**
1. 生成された `build/web/` をWebサーバーにアップロード
2. HTTPS設定
3. セキュリティヘッダー設定

## ⚙️ 設定ファイル詳細

### config/production.yaml
本番環境の設定が記載されています：

```yaml
environment:
  name: "production"
  debug_mode: false

security:
  encryption:
    algorithm: "AES-256-GCM"
  secure_storage:
    android:
      encrypted_shared_preferences: true
    ios:
      accessibility: "first_unlock_this_device"

performance:
  image_cache:
    max_cache_size: "100MB"
  database_optimization:
    enable_indices: true
```

### config/staging.yaml
ステージング環境用設定：

```yaml
environment:
  name: "staging"
  debug_mode: true

logging:
  level: "DEBUG"
  console_output: true
```

## 🔒 セキュリティ考慮事項

### APIキー管理
- ✅ **本番**: Flutter Secure Storage（暗号化）
- ✅ **開発**: `.env`ファイル（gitignore対象）
- ❌ **禁止**: コード内ハードコーディング

### データ保護
- SQLite データベースの暗号化
- 個人情報の適切な取り扱い
- HTTPS通信の強制

### 権限設定
```xml
<!-- Android: android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

```xml
<!-- iOS: ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>このアプリは近くの中華料理店を検索するために位置情報を使用します</string>
```

## 📊 監視・運用

### ログ監視
- 本番環境: INFOレベル以上
- エラー発生時の自動アラート設定推奨

### パフォーマンス監視
- アプリ起動時間
- API応答時間
- データベースクエリ性能

### ユーザー分析
- クラッシュレポート
- パフォーマンス指標
- ユーザー行動分析（プライバシー配慮）

## 🚨 トラブルシューティング

### よくある問題

#### 1. APIキー関連エラー
```
Error: API key not found
```
**解決方法**:
```bash
# APIキー再設定
./scripts/setup-production-keys.sh
```

#### 2. ビルドエラー
```
Error: Failed to build for production
```
**解決方法**:
```bash
# 環境リセット
flutter clean
flutter pub get
./scripts/check-production-ready.sh
```

#### 3. 位置情報エラー
```
Error: Location permissions denied
```
**解決方法**:
- AndroidManifest.xml、Info.plistの権限設定確認
- ランタイム権限要求の実装確認

## 📋 チェックリスト

### デプロイ前チェック
- [ ] `./scripts/check-production-ready.sh` 実行・合格
- [ ] APIキー本番用に変更
- [ ] 証明書・署名設定完了
- [ ] テスト実行・全合格
- [ ] セキュリティ監査実施

### デプロイ後チェック
- [ ] アプリ起動確認
- [ ] 主要機能動作確認
- [ ] API通信確認
- [ ] 位置情報取得確認
- [ ] データベース動作確認

### 運用チェック
- [ ] ログ監視設定
- [ ] アラート設定
- [ ] バックアップ設定
- [ ] 更新計画策定

## 🔄 アップデート手順

### パッチリリース (1.0.x)
```bash
# バージョン更新
# pubspec.yaml: version: 1.0.1+2

# 本番デプロイ
./scripts/deploy-production.sh [platform]
```

### マイナーリリース (1.x.0)
```bash
# フィーチャーブランチからマージ
git checkout main
git merge feature/new-feature

# バージョン更新
# pubspec.yaml: version: 1.1.0+3

# 本番デプロイ
./scripts/deploy-production.sh [platform]
```

## 🆘 緊急時対応

### ロールバック手順
1. App Store Connect / Google Play Consoleで以前のバージョンに戻す
2. 緊急パッチの準備
3. ユーザー告知

### インシデント対応
1. エラーログ確認
2. 影響範囲特定
3. 応急処置実施
4. 根本原因調査
5. 再発防止策実装

## 📞 サポート

### 技術サポート
- 開発チーム内でのコードレビュー
- Stack Overflow、Flutter公式ドキュメント

### API サポート
- **HotPepper API**: [リクルートサポート](https://webservice.recruit.co.jp/support/)
- **Google Maps API**: [Google Cloud サポート](https://cloud.google.com/support)

---

**最終更新**: $(date +"%Y年%m月%d日")  
**バージョン**: 1.0.0  
**作成者**: 町中華探索アプリ開発チーム