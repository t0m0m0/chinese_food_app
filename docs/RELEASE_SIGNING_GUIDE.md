# 🔐 Android リリース署名ガイド

## 概要

中華料理アプリ「マチアプ」のAndroid本番リリース用署名設定ガイドです。

## 署名設定の種類

### 1. デバッグ証明書（開発用）
- **用途**: 開発・テスト環境
- **設定**: 自動適用（環境変数不要）
- **セキュリティ**: 低（公開キー）

### 2. リリース証明書（本番用）
- **用途**: Google Play Store配布
- **設定**: 環境変数必須
- **セキュリティ**: 高（秘密キー管理）

## 環境変数設定

### 本番リリース用環境変数

```bash
# 証明書ファイルパス
export RELEASE_STORE_FILE=/path/to/release.keystore

# キーエイリアス名
export RELEASE_KEY_ALIAS=release_key

# キーストアパスワード
export RELEASE_STORE_PASSWORD=your_store_password

# キーパスワード
export RELEASE_KEY_PASSWORD=your_key_password
```

### GitHub Actions用シークレット設定

GitHub Repository → Settings → Secrets and variables → Actions

| シークレット名 | 説明 | 形式 |
|--------------|------|------|
| `RELEASE_STORE_FILE_BASE64` | keystoreファイル（Base64エンコード） | Base64文字列 |
| `RELEASE_KEY_ALIAS` | キーエイリアス名 | 文字列 |
| `RELEASE_STORE_PASSWORD` | キーストアパスワード | 文字列 |
| `RELEASE_KEY_PASSWORD` | キーパスワード | 文字列 |

### Base64エンコード手順

```bash
# keystoreファイルをBase64エンコード
base64 -i release.keystore | pbcopy
# ↑ macOS用、Linux: base64 release.keystore | xclip -selection clipboard
```

## 署名証明書作成手順

### 1. 新しいkeystore作成

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias release_key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass your_store_password \
  -keypass your_key_password
```

### 2. 証明書情報確認

```bash
keytool -list -v -keystore release.keystore -alias release_key
```

## ビルド手順

### 1. 署名設定確認

```bash
# 署名設定チェックスクリプト実行
./scripts/setup-release-signing.sh
```

### 2. リリースビルド実行

```bash
# App Bundle（Play Store推奨）
flutter build appbundle --release

# APK（直接配布用）
flutter build apk --release
```

### 3. 署名確認

```bash
# App Bundleの署名確認
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# APKの署名確認
jarsigner -verify -verbose -certs build/app/outputs/apk/release/app-release.apk
```

## 自動署名フロー

### 環境変数設定時
1. ✅ リリース証明書で署名
2. ✅ ProGuard有効化
3. ✅ コード難読化
4. ✅ 本番用applicationId

### 環境変数未設定時
1. ⚠️  デバッグ証明書で署名（警告表示）
2. ⚠️  開発用設定継続
3. ℹ️  `flutter run --release`は正常動作

## セキュリティ注意事項

### ⚠️ 重要な警告

- **keystoreファイルは絶対にGitにコミットしない**
- **パスワードは環境変数かシークレット管理ツールで管理**
- **keystoreファイルのバックアップを安全な場所に保管**

### 📋 チェックリスト

- [ ] keystoreファイルが.gitignoreに含まれている
- [ ] 環境変数が適切に設定されている
- [ ] ビルド時に適切な証明書が使用されている
- [ ] 署名確認コマンドで検証済み

## トラブルシューティング

### よくある問題

#### ⚠️ 警告: デバッグ証明書使用
```
⚠️  リリースビルドですがデバッグ証明書を使用しています
   本番リリースには環境変数でリリース証明書を設定してください:
   RELEASE_STORE_FILE, RELEASE_KEY_ALIAS, RELEASE_STORE_PASSWORD, RELEASE_KEY_PASSWORD
```

**解決方法**: 環境変数を正しく設定してください。

#### ❌ keystoreファイルが見つからない
**解決方法**: RELEASE_STORE_FILEのパスを確認してください。

#### ❌ パスワード認証失敗
**解決方法**: RELEASE_STORE_PASSWORD、RELEASE_KEY_PASSWORDを確認してください。

## 参考リンク

- [Android Developer - App signing](https://developer.android.com/studio/publish/app-signing)
- [Flutter - Build and release for Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console - App signing](https://support.google.com/googleplay/android-developer/answer/9842756)