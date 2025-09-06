# 統一例外処理システム移行計画

## 概要

Issue #156で実装された統一例外処理システムへの段階的移行計画書です。
既存システムとの互換性を保ちながら、計画的に新システムへ移行します。

## 移行スケジュール

### Phase 1: 基盤整備 (完了済み)
**期間**: 2024年12月 - 実装完了済み

- [x] 統一例外処理システムの実装
- [x] TDDによる包括的テスト作成
- [x] エラーハンドリングガイドライン策定
- [x] CI設定での警告抑制

### Phase 2: 新規開発での採用 (即時開始)
**期間**: 即時 - 継続

#### 対象
- 新規作成するファイル
- 大幅修正が必要な既存ファイル

#### アクション
- [ ] 新規Repository実装時の統一例外システム採用
- [ ] 新規APIサービス実装時の適用
- [ ] 新規Provider実装時の適用
- [ ] コードレビュー時の統一例外使用推奨

### Phase 3: 高頻度使用箇所の移行 (2週間以内)
**期間**: 2024年12月下旬 - 2025年1月上旬

#### 優先度: High
1. **HotpepperApiService** (`lib/data/datasources/hotpepper_api_datasource.dart`)
   - 現在: `ApiException`, `NetworkException`の混在使用
   - 移行後: `UnifiedNetworkException`への統一

2. **BaseApiService** (`lib/core/network/base_api_service.dart`)
   - 現在: レガシー例外の大量使用
   - 移行後: 統一例外システム

3. **AppHttpClient** (`lib/core/network/app_http_client.dart`)
   - 現在: `NetworkException`中心の使用
   - 移行後: `UnifiedNetworkException`各種ファクトリメソッド活用

#### 移行作業内容
```dart
// 移行前
throw NetworkException('Network error', statusCode: 500);
throw ApiException('API error', statusCode: 400);

// 移行後
throw UnifiedNetworkException.http('Network error', statusCode: 500);
throw UnifiedNetworkException.api('API error', statusCode: 400);
```

### Phase 4: 中頻度使用箇所の移行 (1ヶ月以内)
**期間**: 2025年1月 - 2025年2月

#### 優先度: Medium
1. **Repository層全般**
   - `StoreRepository`
   - `LocationRepository`
   - その他データアクセス層

2. **Provider層の例外処理**
   - `SearchProvider`
   - `StoreProvider`
   - エラー状態管理の統一化

3. **テストファイルの更新**
   - モックオブジェクトの更新
   - 期待値の調整

### Phase 5: 残存箇所の完全移行 (3ヶ月以内)
**期間**: 2025年2月 - 2025年3月

#### 対象
- 低頻度使用箇所
- テストファイル全般
- ユーティリティクラス

#### 完了条件
- [ ] `@Deprecated`警告の完全解消
- [ ] `analysis_options.yaml`から警告抑制設定削除
- [ ] 静的解析警告ゼロの達成

## 移行チェックリスト

### 各ファイル移行時の確認項目

#### ✅ コード変更
- [ ] `import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';` の追加
- [ ] 旧例外クラスの新例外クラスへの置換
- [ ] ファクトリコンストラクタの適切な使用
- [ ] エラーメッセージの日本語統一

#### ✅ テスト更新
- [ ] テスト内の例外インスタンス作成の更新
- [ ] 期待値（エラーメッセージ等）の調整
- [ ] モックオブジェクトの更新

#### ✅ 品質確認
- [ ] `flutter analyze` でエラー・警告なし
- [ ] `flutter test` で全テスト通過
- [ ] 実機での動作確認

### リスク管理

#### 高リスク箇所
1. **中核API処理**
   - HotpepperApiService
   - BaseApiService
   
   **軽減策**: ステージング環境での十分な検証

2. **エラー表示UI**
   - Provider層のエラー状態管理
   - Widget層のエラー表示

   **軽減策**: UI表示テストの実施

#### ロールバック計画
各Phase完了時点でのスナップショット作成:
```bash
git tag migration-phase-1-complete
git tag migration-phase-2-complete
# 以降同様
```

### マイルストーン

| Phase | 完了予定日 | 成果物 | 成功指標 |
|-------|-----------|--------|----------|
| Phase 1 | 完了済み | 統一例外システム | テスト23件通過 |
| Phase 2 | 継続中 | 新規開発での採用 | 新規ファイル100%採用 |
| Phase 3 | 2025/01/15 | 高頻度箇所移行 | 主要APIサービス移行完了 |
| Phase 4 | 2025/02/28 | 中頻度箇所移行 | Repository/Provider層移行 |
| Phase 5 | 2025/03/31 | 完全移行達成 | 警告ゼロ・全テスト通過 |

### 進捗管理

#### 週次レポート項目
- 移行完了ファイル数
- 残存警告数
- テスト通過率
- 発見された課題と対応

#### 移行状況の可視化
```bash
# 進捗確認コマンド
flutter analyze | grep deprecated_export_use | wc -l
# → 残存警告数の確認
```

### 成功条件

#### 最終目標
1. **技術的成功**
   - 静的解析警告: 0件
   - テスト通過率: 100%
   - コードカバレッジ: 維持または向上

2. **運用的成功**  
   - デバッグ効率の向上
   - エラー対応時間の短縮
   - 開発者体験の向上

3. **ユーザー体験向上**
   - 分かりやすい日本語エラーメッセージ
   - 適切な重要度によるログ管理
   - レスポンシブなエラー処理

### 参考資料

- [エラーハンドリングガイドライン](ERROR_HANDLING_GUIDE.md)
- [統一例外システム設計ドキュメント](unified_exceptions_export.dart)
- [Issue #156](https://github.com/t0m0m0/chinese_food_app/issues/156)
- [PR #164](https://github.com/t0m0m0/chinese_food_app/pull/164)

---

この移行計画により、段階的かつ安全に統一例外処理システムへの移行を実現し、
コードベース全体の品質向上と保守性改善を目指します。