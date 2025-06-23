# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

2. **開発・実装**
   - 適切な単位で機能を実装
   - コードの品質とアーキテクチャを維持
   - Clean Architecture原則に従う

3. **コミット・プッシュ**
   ```bash
   git add .
   git commit -m "適切なコミットメッセージ"
   git push origin ブランチ名
   ```
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
   - **改善提案**: 具体的なコードサンプル付きコメント
   - **総合評価**: Good Points / Issues Found / Recommendations

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