# 町中華アプリ CI/CD システム

このディレクトリには、町中華探索アプリ「マチアプ」のCI/CDパイプラインが含まれています。

## 🔄 ワークフロー概要

### 1. メインCI/CD (`ci.yml`)
**トリガー**: `master`, `develop`ブランチへのプッシュ、全ブランチのPR

**実行内容**:
- **コード品質チェック**: 静的解析、フォーマット、依存関係チェック
- **テスト実行**: 単体テストとカバレッジ測定
- **ビルドテスト**: Android APK、Webアプリの正常ビルド確認
- **セキュリティスキャン**: 依存関係の脆弱性チェック
- **通知**: 全工程の結果通知

### 2. PR品質チェック (`pr-checks.yml`)
**トリガー**: プルリクエストの作成・更新

**実行内容**:
- **PR品質チェック**: ブランチ名、コミットメッセージの規則確認
- **差分解析**: 変更行数、ファイル種別の分析
- **依存関係チェック**: pubspec.yaml変更時の依存関係確認

### 3. リリース自動化 (`release.yml`)
**トリガー**: `v*.*.*`形式のタグプッシュ

**実行内容**:
- **リリース準備**: リリースノート自動生成、GitHub Release作成
- **Android ビルド**: 本番用APKファイル生成・アップロード
- **Web ビルド**: 本番用Webアプリ生成・アップロード
- **GitHub Pages デプロイ**: WebアプリのGitHub Pages公開

## 📋 品質ゲート

### 必須条件（マージブロック対象）
- ✅ 静的解析（`flutter analyze`）エラーゼロ
- ✅ コードフォーマット（`dart format`）準拠
- ✅ 単体テスト全パス
- ✅ Android/Webビルド成功
- ✅ ブランチ命名規則準拠

### 推奨条件（警告のみ）
- 🟡 テストカバレッジ80%以上
- 🟡 Claude Code署名付きコミット
- 🟡 PR行数500行以下

## 🏷️ ブランチ戦略とCI連携

| ブランチタイプ | CI実行内容 | 品質ゲート |
|----------------|------------|------------|
| `feature/*` | PR品質チェックのみ | 軽量チェック |
| `fix/*` | PR品質チェック + フルCI | 標準品質ゲート |
| `master` | フルCI + デプロイ準備 | 最高品質ゲート |
| `develop` | フルCI（デプロイなし） | 標準品質ゲート |

## 🚀 リリースフロー

### 1. 通常リリース
```bash
# バージョンタグを作成
git tag v1.0.0
git push origin v1.0.0

# 自動的にリリースワークフローが実行される
# - GitHub Releaseページ作成
# - Android APK生成・アップロード
# - Web版ビルド・デプロイ
```

### 2. 手動デプロイ
```bash
# Web版のみ手動デプロイ
gh workflow run release.yml
```

## 📊 モニタリング・レポート

### カバレッジレポート
- **Codecov連携**: PRごとのカバレッジ変化を追跡
- **しきい値**: 80%以上を推奨

### ビルド成果物
- **Android APK**: PR/リリースごとに7日間保持
- **Web ビルド**: GitHub Pagesで永続公開
- **ログ**: GitHub Actionsで30日間保持

### セキュリティ
- **依存関係スキャン**: 既知の脆弱性を自動検出
- **静的解析**: 潜在的なセキュリティ問題を警告

## 🔧 設定とカスタマイズ

### 環境変数・シークレット
現在は不要（パブリックリポジトリ、署名なしビルド）

将来必要になる可能性:
- `ANDROID_KEYSTORE`: Android署名用キーストア
- `APPLE_CERTIFICATES`: iOS署名用証明書
- `FIREBASE_TOKEN`: Firebase Hosting用トークン

### ワークフロー無効化
一時的にワークフローを無効化する場合:
```yaml
# .github/workflows/*.yml の先頭に追加
on:
  workflow_dispatch: # 手動実行のみ
```

## 🐛 トラブルシューティング

### よくある問題

#### ❌ `flutter analyze` エラー
```bash
# ローカルで事前確認
flutter analyze
dart format --set-exit-if-changed .
```

#### ❌ ビルドエラー
```bash
# ローカルでビルドテスト
flutter clean
flutter pub get
flutter build apk --debug
flutter build web
```

#### ❌ テストエラー
```bash
# テスト単体実行
flutter test
flutter test --coverage
```

### CI高速化設定
- **キャッシュ**: Flutter SDK、pub cache自動キャッシュ済み
- **並列実行**: ビルドとテストを並列実行
- **早期終了**: 品質チェック失敗時の早期停止

## 📈 今後の拡張予定

- **iOS CI**: macOS runnerでのiOSビルド
- **E2Eテスト**: Webサイトテスト自動化
- **Performance Testing**: アプリ性能監視
- **Multi-Environment Deploy**: staging/production環境分離
- **Slack/Discord通知**: チーム通知システム