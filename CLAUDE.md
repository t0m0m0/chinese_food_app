# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Language
- **User Communication**: Always respond to the user in Japanese (日本語)
- **Internal Thinking**: Use English for internal reasoning and analysis
- This language setting should be maintained throughout all interactions with this codebase

## Project Overview
# 町中華探索アプリ「マチアプ」仕様書（MVP）

## 概要

町中華を探索・記録するためのモバイルアプリ。  
マッチングアプリ風のUIで店舗をスワイプし、「行きたい」「興味なし」などのステータスを設定できる。  
MVPでは、1人用の記録ツールとして開発し、将来的にはシェア機能も視野に入れる。

## 目的

- 気になる町中華を探し、行きたい店をストックする
- 実際に訪れた町中華を記録として残す
- スワイプや検索など、直感的なUIで町中華探索を楽しめる体験を提供する

## 想定ユーザー

- 町中華が好きな一般ユーザー（初期は開発者自身）
- 一人で地道に店を開拓するのが好きな人
- ラーメン、餃子、定食などのB級グルメファン

## 機能一覧（MVP）

### 1. スワイプ画面（マッチングアプリ風UI）
- 1枚ずつ店舗カードを表示（写真、店名、住所）
- 右スワイプ → 「行きたい」
- 左スワイプ → 「興味なし（bad）」
- スワイプ結果はローカルDB（SQLite）に保存

### 2. 店舗検索
- ホットペッパーAPIを利用した店舗検索
- 現在地 or 地名での検索対応
- 結果をリストとGoogle Map上に表示
- 店舗をタップすると詳細画面へ遷移

### 3. マイメニュー（一覧管理画面）
- 「行きたい」「行った」店の一覧を表示
- タブまたはフィルターで切り替え可能
- 店舗ごとの訪問記録を追加・編集できる

## アプリ構成（タブメニュー）

- スワイプ（店舗との出会い）
- 検索（条件を指定して探す）
- マイメニュー（記録・管理）

## 画面一覧・遷移図
[タブメニュー]
├─ スワイプ
│ └─ 店舗詳細
│ └─ 訪問記録追加/編集
├─ 検索
│ ├─ 検索結果（リスト＆地図）
│ └─ 店舗詳細
│ └─ 訪問記録追加/編集
└─ マイメニュー
├─ 行きたい店一覧
├─ 行った店一覧
└─ 店舗詳細
└─ 訪問記録追加/編集



## データモデル

### Store（店舗）

| フィールド | 型 | 説明 |
|------------|----|------|
| id | string | 店舗ID（APIまたはUUID） |
| name | string | 店名 |
| address | string | 住所 |
| lat / lng | float | 緯度経度 |
| status | enum('want_to_go', 'visited', 'bad') | ステータス |
| memo | string（任意） | 店舗についての自由メモ |
| created_at | datetime | 登録日時 |

### VisitRecord（訪問記録）

| フィールド | 型 | 説明 |
|------------|----|------|
| id | string | 記録ID |
| store_id | string | 対応する店舗ID |
| visited_at | datetime | 訪問日時 |
| menu | string | 食べたメニュー |
| memo | string | 感想などのメモ |
| created_at | datetime | 記録日時 |

### Photo（写真）

| フィールド | 型 | 説明 |
|------------|----|------|
| id | string | 写真ID |
| store_id | string | 店舗ID |
| visit_id | string（任意） | 訪問記録ID |
| file_path | string | ローカルの保存パス |
| created_at | datetime | 保存日時 |

## 使用API・外部サービス

| サービス名 | 用途 |
|------------|------|
| ホットペッパーグルメAPI | 店舗情報の取得（検索機能） |
| Google Maps SDK | 地図表示、ピン表示 |

## 保存方式

- SQLiteによるローカルデータ保存
- ステータス・記録・写真はローカルで完結
- APIから取得したデータはキャッシュせず都度取得（規約順守）

## Development Commands

### Setup & Dependencies
```bash
flutter pub get
```

### Running
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome         # Run on web
flutter run -d windows/macos/linux  # Run on desktop
```

### Code Quality
```bash
flutter analyze               # Static analysis
flutter test                  # Run all tests
flutter test test/widget_test.dart  # Run specific test
```

### Building
```bash
flutter build apk           # Android APK
flutter build appbundle     # Android App Bundle  
flutter build ios           # iOS
flutter build web           # Web
flutter build windows/macos/linux  # Desktop
```

### WSL2環境での注意点
WSL2環境では、Windows版FlutterではなくLinux版Flutterを使用してください：
```bash
# Linux版Flutter（WSL2推奨）
export PATH="$HOME/flutter/bin:$PATH"
dart format .                 # 正常動作
```

Windows版Flutter (`/mnt/c/dev/flutter`) はWSL2でCRLF問題が発生するため非推奨です。

## Architecture
- **Entry Point**: `lib/main.dart` - Material Design app with StatefulWidget counter example
- **Testing**: Standard Flutter widget testing in `test/`
- **Linting**: Uses `flutter_lints` package via `analysis_options.yaml`
- **Dependencies**: Minimal - only `cupertino_icons` and `flutter_lints`
- **Multi-platform**: Full platform support configured in respective directories

## Environment
- Flutter SDK 3.8.1+
- Private package (not published to pub.dev)

## Development Workflow

このプロジェクトでは品質管理とレビューベースの開発フローを採用しています。

### 基本フロー

1. **ブランチ作成**
   ```bash
   git checkout -b feature/機能名
   # または
   git checkout -b fix/修正内容
   # または  
   git checkout -b docs/文書更新内容
   ```

2. **開発・実装（TDD必須）**
   - **Red**: 失敗するテストから開始
   - **Green**: テストが通る最小限の実装
   - **Refactor**: コード品質向上とリファクタリング
   - Clean Architecture原則に従う
   - 適切な単位で機能を実装

3. **コミット・プッシュ**
   ```bash
   # 必須: コミット前のフォーマット実行
   dart format .
   
   git add .
   git commit -m "適切なコミットメッセージ"
   git push origin ブランチ名
   ```
   - **必須手順**: コミット前に必ず`dart format .`を実行
   - **コミットメッセージ規則**: 日本語で簡潔に機能説明
   - **適切な単位**: 1つの機能や修正につき1コミット
   - **Claude Code署名**: 自動付与される`🤖 Generated with Claude Code`を含める

4. **プルリクエスト作成**
   ```bash
   gh pr create --title "機能名" --body "説明"
   ```
   - 実装内容の詳細説明
   - Test planの記載
   - 必要に応じてスクリーンショット

5. **セルフレビュー実施**
   - **コードレビュー**: GitHub PR画面で詳細レビュー
   - **品質チェック**: エラーハンドリング、パフォーマンス、アーキテクチャ
   - **QAレビュー**: QA担当者目線での厳格な品質検証
   - **改善提案**: 具体的なコードサンプル付きコメント
   - **総合評価**: Good Points / Issues Found / Recommendations
   - **レビューコメント**: GitHub PRへの詳細な指摘事項記録

6. **レビュー指摘対応**
   - 指摘事項を同一ブランチで修正
   - 適切なコミットメッセージで変更内容を説明
   - 修正完了後にプッシュ

7. **最終確認・マージ**
   ```bash
   gh pr merge PR番号 --merge
   ```
   - すべての指摘事項対応完了を確認
   - 最終品質チェック実施
   - masterブランチにマージ実行

### 品質基準

#### 必須要件
- **TDD（テスト駆動開発）**: Red → Green → Refactor サイクル厳守
- **テストカバレッジ**: 新機能は80%以上のカバレッジ必須
- **コードフォーマット**: コミット前に必ず`dart format .`実行
- **エラーハンドリング**: try-catch とDatabaseException対応
- **アーキテクチャ準拠**: Clean Architecture + Repository Pattern
- **型安全性**: null safety完全対応
- **命名規則**: Dart標準命名規則遵守

#### 推奨要件  
- **ページネーション**: 大量データ対応
- **トランザクション**: 複数テーブル操作での整合性保証
- **マイグレーション**: 将来のスキーマ変更対応
- **ドキュメント**: コードコメントと説明

### ブランチ命名規則

| プレフィックス | 用途 | 例 |
|----------------|------|-----|
| `feature/` | 新機能開発 | `feature/swipe-ui`, `feature/search-api` |
| `fix/` | バグ修正 | `fix/database-improvements`, `fix/null-safety` |
| `docs/` | 文書更新 | `docs/update-readme`, `docs/api-spec` |
| `refactor/` | リファクタリング | `refactor/clean-architecture` |
| `test/` | テスト追加 | `test/unit-tests`, `test/integration` |

### コミットメッセージ例

```
町中華探索アプリのスワイプUI実装

- flutter_card_swiperによるマッチングアプリ風UI
- 右スワイプ「行きたい」、左スワイプ「興味なし」対応  
- Store repositoryとの連携でローカルDB保存
- Material Design 3準拠のカードデザイン

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 注意事項

- **masterブランチ直接コミット禁止**: 必ずブランチ経由
- **レビュー必須**: セルフレビューまたはペアレビュー実施
- **品質優先**: 動作するだけでなく、保守しやすいコード
- **段階的実装**: 大きな機能は複数PRに分割

## レビュープロセス

### QAレビューガイドライン

PRレビューでは以下の観点から厳格にチェックします：

#### 🚨 **ブロッカー問題（必須修正）**
- **データ整合性**: NULL制約、CHECK制約、外部キー制約
- **セキュリティ**: 例外処理、入力検証、SQLインジェクション対策
- **エラーハンドリング**: try-catch、適切な例外処理
- **テストカバレッジ**: エッジケース、異常系テスト

#### ⚠️ **重要問題（推奨修正）**
- **パフォーマンス**: インデックス、クエリ最適化
- **バリデーション**: 入力値検証、ビジネスルール検証
- **コード品質**: 可読性、保守性、設計パターン

#### 🔧 **軽微問題（改善提案）**
- **ドキュメント**: JavaDoc、コメント
- **命名規則**: 変数名、メソッド名の適切性
- **コード重複**: DRY原則の適用

### レビューコメント記録

```bash
# QAレビュー結果をPRにコメント
gh pr comment PR番号 --body "レビュー結果詳細"

# 指摘事項の分類
# ❌ ブロッカー問題: REJECT（変更要求）
# ⚠️ 重要問題: CHANGES REQUESTED  
# 🔧 軽微問題: APPROVED WITH SUGGESTIONS
```

### レビュー後の対応フロー

1. **指摘事項対応**: 同一ブランチで修正実装
2. **追加テスト**: 不足していたテストケース追加
3. **修正コミット**: 指摘事項ごとに適切なコミットメッセージ
4. **再レビュー依頼**: `gh pr comment --body "修正完了。再レビューお願いします"`

## TDD（テスト駆動開発）ガイドライン

### TDDサイクル

1. **Red（レッド）フェーズ**
   ```bash
   # 失敗するテストを作成
   flutter test test/path/to/test.dart  # 失敗することを確認
   ```
   - 機能要件を満たすテストを先に作成
   - テストが失敗することを確認
   - 必要最小限のテストから開始

2. **Green（グリーン）フェーズ**
   ```bash
   # テストが通る最小限の実装
   flutter test test/path/to/test.dart  # 成功することを確認
   ```
   - テストが通る最小限のコードを実装
   - 可読性や設計は後回し
   - まずは動作することを優先

3. **Refactor（リファクタ）フェーズ**
   ```bash
   dart format .                        # フォーマット実行
   flutter test                         # 全テスト実行
   flutter analyze                      # 静的解析実行
   ```
   - コード品質向上
   - 設計パターンの適用
   - パフォーマンス最適化
   - テストが通ることを確認しながら改善

### テスト種別と配置

```
test/
├── unit/              # 単体テスト
│   ├── models/        # モデルクラステスト
│   ├── repositories/  # Repository層テスト
│   └── datasources/   # DataSource層テスト
├── widget/            # ウィジェットテスト
│   └── pages/         # ページ単位テスト
├── integration/       # 統合テスト
│   └── database/      # DB統合テスト
└── e2e/              # E2Eテスト
    └── user_flows/    # ユーザーフローテスト
```

### テスト命名規約

- **ファイル名**: `機能名_test.dart`
- **テスト名**: `should_期待する動作_when_条件`
- **グループ名**: 機能や責務ごとにグルーピング

### 例：TDDによるRepository実装

```dart
// 1. Red: テスト作成
test('should_return_stores_when_valid_status_provided', () async {
  // given
  const status = 'want_to_go';
  
  // when
  final result = await repository.getStoresByStatus(status);
  
  // then
  expect(result, isA<List<Store>>());
  expect(result.every((store) => store.status == status), isTrue);
});

// 2. Green: 最小実装
Future<List<Store>> getStoresByStatus(String status) async {
  return []; // 最小実装
}

// 3. Refactor: 実際の実装とコード改善
Future<List<Store>> getStoresByStatus(String status) async {
  try {
    return await _localDatasource.getStoresByStatus(status);
  } on DatabaseException catch (e) {
    throw Exception('Failed to fetch stores: ${e.toString()}');
  }
}
```

## Issue実装ワークフロー

### Issue実装の基本フロー

GitHub Issueに基づく実装は以下の手順で進めます：

1. **Issue選定と準備**
   ```bash
   # 実装するissueを確認
   gh issue view 10
   
   # 依存関係を確認（技術タスクから開始推奨）
   # データベース → Repository → UI の順序
   ```

2. **ブランチ作成とTDD開始**
   ```bash
   # issue内容に基づいたブランチ名
   git checkout -b feature/database-schema-migration
   
   # Red: 失敗するテストを先に作成
   flutter test test/path/to/new_test.dart  # 失敗確認
   ```

3. **TDDサイクル実行**
   ```bash
   # Green: 最小実装でテスト通す
   flutter test test/path/to/new_test.dart  # 成功確認
   
   # Refactor: コード品質向上
   dart format .
   flutter analyze
   flutter test
   ```

4. **実装完了確認**
   ```bash
   # Issue内の受け入れ基準をチェック
   # - [ ] 基本機能 ✅
   # - [ ] UI/UX ✅  
   # - [ ] 技術要件 ✅
   # - [ ] 定義完了 ✅
   ```

5. **コミット・プッシュ・PR**
   ```bash
   git add .
   git commit -m "issue #10: データベーススキーマとマイグレーション実装"
   git push origin feature/database-schema-migration
   gh pr create --title "issue #10: データベーススキーマとマイグレーション実装"
   ```

### Issue実装の優先順序

技術的依存関係に基づいた実装順序：

1. **Foundation Layer**
   - issue #10: データベーススキーマ（**最優先**）
   - issue #11: テスト実装
   - issue #12: セキュリティ強化

2. **Business Logic Layer**
   - Repository/DataSource層の実装
   - Model/Entity層の完成

3. **Presentation Layer**
   - issue #5: スワイプ機能
   - issue #6: 検索機能  
   - issue #7: マイメニュー
   - issue #8: 訪問記録
   - issue #9: 店舗詳細

### Issue状況の追跡

```bash
# 進行中のissue確認
gh issue list --state open --assignee @me

# 完了したissue確認  
gh issue list --state closed

# issue #10の進捗確認
gh issue view 10
```

### Issue完了時のチェックリスト

- [ ] 受け入れ基準全て満たす
- [ ] TDDサイクル完了（Red→Green→Refactor）
- [ ] テストカバレッジ80%以上
- [ ] `flutter analyze`エラーゼロ
- [ ] `dart format .`実行済み
- [ ] PR作成・レビュー完了
- [ ] CI/CDパイプライン成功
- [ ] issueクローズ

## CI/CD システム

### 自動化パイプライン

このプロジェクトは包括的なCI/CDシステムを採用し、コード品質とリリース品質を自動保証します。

#### 🔄 メインCI (`ci.yml`)
**実行タイミング**: `master`/`develop`ブランチプッシュ、全PR作成・更新

1. **コード品質チェック**
   ```bash
   flutter analyze          # 静的解析
   dart format --check      # フォーマット確認
   flutter pub deps         # 依存関係チェック
   ```

2. **テスト実行**
   ```bash
   flutter test --coverage  # 単体テスト + カバレッジ
   ```

3. **ビルドテスト**
   ```bash
   flutter build apk        # Android APK
   flutter build web        # Webアプリ
   ```

4. **セキュリティスキャン**
   - 依存関係の脆弱性チェック
   - コードの潜在的問題検出

#### 📋 PR品質チェック (`pr-checks.yml`) 
**実行タイミング**: プルリクエスト作成・更新

- **命名規則チェック**: ブランチ名が`feature/`, `fix/`, `docs/`等で開始
- **コミットメッセージ**: Claude Code署名確認
- **差分解析**: 変更行数、ファイル種別分析
- **依存関係監視**: pubspec.yaml変更時の影響確認

#### 🚀 リリース自動化 (`release.yml`)
**実行タイミング**: `v*.*.*`形式のタグプッシュ

- **リリースノート自動生成**: 前回タグからの変更履歴
- **成果物生成**: Android APK、Web版tar.gz
- **GitHub Release**: 自動リリースページ作成
- **GitHub Pages**: Web版自動デプロイ

### 品質ゲート

#### 必須条件（マージブロック）
- ✅ `flutter analyze`エラーゼロ
- ✅ `dart format`準拠
- ✅ 単体テスト全パス
- ✅ Android/Webビルド成功
- ✅ ブランチ命名規則準拠

#### 推奨条件（警告）
- 🟡 テストカバレッジ80%以上
- 🟡 Claude Code署名付きコミット
- 🟡 PR変更行数500行以下

### リリースフロー

```bash
# 新しいバージョンをリリース
git tag v1.0.0
git push origin v1.0.0

# 自動実行される処理:
# 1. GitHub Releaseページ生成
# 2. Android APK自動ビルド・アップロード  
# 3. Web版ビルド・GitHub Pages デプロイ
# 4. リリースノート自動生成
```

### モニタリング

- **カバレッジ**: Codecov連携でPRごとの変化追跡
- **成果物**: Android APK/Web版を7日間保持
- **セキュリティ**: 依存関係脆弱性の自動検出
- **ログ**: GitHub Actionsで30日間保持

詳細は `.github/README.md` を参照してください。