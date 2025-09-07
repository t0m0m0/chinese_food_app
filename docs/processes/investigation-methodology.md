# Issue調査方法論 - 標準プロセス

## 📋 概要

既存Issue実装状況の効率的な調査方法を標準化し、重複作業を防止し調査品質を向上する。

## 🔍 調査プロセス

### Phase 1: 事前確認 (5-10分)

#### 1.1 Issue基本情報確認
```bash
# Issue詳細取得
gh issue view {issue-number} --json title,body,labels,milestone

# 関連PR確認  
gh pr list --search "#{issue-number}"
```

#### 1.2 ブランチ・コミット履歴確認
```bash
# 関連ブランチ検索
git branch -a | grep -i {issue-keyword}

# 最近のコミット確認
git log --oneline --grep="#{issue-number}" -10
git log --oneline --grep="{issue-keyword}" -10
```

#### 1.3 実装範囲の事前推定
- Issue description解析
- 変更対象ファイル/ディレクトリの特定
- 実装複雑度の評価

### Phase 2: コードベース調査 (15-30分)

#### 2.1 実装確認
```bash
# 機能実装の確認
grep -r "{feature-keyword}" lib/
find lib/ -name "*{feature}*" -type f

# テスト実装の確認  
find test/ -name "*{feature}*" -type f
grep -r "{feature-keyword}" test/
```

#### 2.2 アーキテクチャ確認
```bash
# 依存関係確認
grep -r "import.*{feature}" lib/
grep -r "export.*{feature}" lib/

# 設定・定数確認
grep -r "{feature}" lib/core/config/
grep -r "{feature}" lib/core/constants/
```

### Phase 3: 動作確認 (10-20分)

#### 3.1 テスト実行
```bash
# 関連テスト実行
flutter test test/unit/**/*{feature}*
flutter test test/widget/**/*{feature}*

# 全テスト実行（必要時）
flutter test --reporter=compact
```

#### 3.2 品質確認
```bash
# コード品質
dart format --dry-run .
flutter analyze

# ビルド確認（必要時）
flutter build apk --debug
```

### Phase 4: 調査結果記録 (5-15分)

#### 4.1 調査レポート作成
- **テンプレート**: `docs/investigations/{issue-number}-{feature}-investigation.md`
- **必須項目**: 調査方法、確認済み機能、次アクション
- **推奨項目**: コード例、テスト結果、品質メトリクス

#### 4.2 Issue/PR管理
- Issue状態の更新（Close/Comment）
- 関連PRの状態確認
- 次フェーズ用Issue作成（必要時）

## 📊 調査判定基準

### ✅ 実装完了の判定基準
1. **機能実装**: 要求機能がコードに実装されている
2. **テスト実装**: 適切なテストケースが存在し通過する
3. **品質基準**: フォーマット・静的解析が通過する
4. **統合確認**: 既存システムとの統合が適切

### ⏳ 部分実装の判定基準  
1. **基盤実装**: コア機能は実装済みだが周辺機能が不足
2. **テスト不足**: 機能実装済みだがテストカバレッジ不足
3. **品質課題**: 機能動作するが品質基準未達成

### ❌ 未実装の判定基準
1. **機能欠如**: 要求機能が実装されていない
2. **テスト皆無**: テストが存在しない  
3. **品質問題**: 重大な品質問題が存在

## 🚀 効率化のベストプラクティス

### 事前確認の徹底
- ブランチ作成前に必ず事前確認を実行
- 重複調査を防止するための履歴確認
- Issue詳細の十分な理解

### 段階的調査アプローチ
- 軽量確認 → 詳細調査の段階的実行
- 早期の実装状況判定
- 不要な深掘り調査の回避

### 標準化されたドキュメント
- テンプレートの活用
- 一貫したフォーマット  
- 検索可能な記録方式

### 自動化の活用
- スクリプト化可能な調査手順
- CI/CDとの連携
- 品質チェックの自動実行

## 📝 調査レポートテンプレート

### 基本テンプレート
```markdown
# Issue #{number} {title} 調査レポート

**調査日**: YYYY-MM-DD
**調査者**: {name}
**所要時間**: {duration}

## 📋 調査概要
{brief-summary}

## 🔍 調査方法
{investigation-methods}

## ✅/⏳/❌ 実装状況
{implementation-status}

## 📊 確認結果
{verification-results}

## 🎯 次アクション
{recommended-actions}

## 📈 品質メトリクス
{quality-metrics}
```

## ⚠️ 注意事項

### 避けるべき調査パターン
- ❌ 事前確認なしでのブランチ作成
- ❌ 包括的調査の過剰実行  
- ❌ 調査結果の記録不備
- ❌ Issue管理の放置

### 推奨調査パターン  
- ✅ 段階的で効率的な調査
- ✅ 適切な記録とドキュメント化
- ✅ Issue管理の徹底
- ✅ 次フェーズの明確化

---

*この方法論は継続的に改善され、プロジェクトの成熟とともに発展します。*