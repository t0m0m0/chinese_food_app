# セキュリティIssue作成ガイド

このガイドでは、`SECURITY_ISSUES.md` に記載された各セキュリティ課題をGitHub Issueとして作成する手順を説明します。

---

## 🔧 作成手順

### 方法1: GitHub CLI を使用（推奨）

```bash
# Issue 1: 暗号化実装の改善
gh issue create \
  --title "[Security][Critical] 暗号化実装の改善：XOR暗号からAES-GCMへの移行" \
  --body-file .github/issue_templates/security_issue_1.md \
  --label "security,critical,enhancement"

# Issue 2: SSL証明書バイパスの制限
gh issue create \
  --title "[Security][Critical] SSL証明書バイパス機能の制限" \
  --body-file .github/issue_templates/security_issue_2.md \
  --label "security,critical,bug"

# Issue 3: 入力検証の強化
gh issue create \
  --title "[Security][Medium] 入力検証の強化" \
  --body-file .github/issue_templates/security_issue_3.md \
  --label "security,enhancement,validation"

# Issue 4: ログ出力のセキュリティ改善
gh issue create \
  --title "[Security][Medium] ログ出力のセキュリティ改善" \
  --body-file .github/issue_templates/security_issue_4.md \
  --label "security,enhancement,logging"
```

### 方法2: GitHub Web UIを使用

1. リポジトリページの **Issues** タブを開く
2. **New issue** ボタンをクリック
3. 以下の情報を `SECURITY_ISSUES.md` から各Issueにコピー&ペースト：
   - Title（タイトル）
   - Body（本文）
   - Labels（ラベル）

---

## 📋 Issue一覧

### Issue 1: 暗号化実装の改善

```
Title: [Security][Critical] 暗号化実装の改善：XOR暗号からAES-GCMへの移行
Labels: security, critical, enhancement
Assignees: （担当者を指定）
Priority: P0（最優先）
```

### Issue 2: SSL証明書バイパスの制限

```
Title: [Security][Critical] SSL証明書バイパス機能の制限
Labels: security, critical, bug
Assignees: （担当者を指定）
Priority: P0（最優先）
```

### Issue 3: 入力検証の強化

```
Title: [Security][Medium] 入力検証の強化
Labels: security, enhancement, validation
Assignees: （担当者を指定）
Priority: P1（高優先）
```

### Issue 4: ログ出力のセキュリティ改善

```
Title: [Security][Medium] ログ出力のセキュリティ改善
Labels: security, enhancement, logging
Assignees: （担当者を指定）
Priority: P1（高優先）
```

---

## 🏷️ ラベルの説明

プロジェクトに以下のラベルが存在しない場合は作成してください：

| ラベル | 色 | 説明 |
|---|---|---|
| `security` | `#d73a4a` | セキュリティ関連の課題 |
| `critical` | `#b60205` | 緊急対応が必要 |
| `enhancement` | `#a2eeef` | 新機能・改善 |
| `bug` | `#d73a4a` | バグ修正 |
| `validation` | `#0e8a16` | 入力検証関連 |
| `logging` | `#fbca04` | ログ・デバッグ関連 |

### ラベル作成コマンド（GitHub CLI）

```bash
gh label create security --color d73a4a --description "セキュリティ関連の課題"
gh label create critical --color b60205 --description "緊急対応が必要"
gh label create enhancement --color a2eeef --description "新機能・改善"
gh label create bug --color d73a4a --description "バグ修正"
gh label create validation --color 0e8a16 --description "入力検証関連"
gh label create logging --color fbca04 --description "ログ・デバッグ関連"
```

---

## 📊 マイルストーンの設定（推奨）

セキュリティ改善を追跡するためのマイルストーンを作成：

```bash
gh milestone create "Security Hardening v1.1" \
  --description "セキュリティ脆弱性の修正と強化" \
  --due-date 2025-12-15
```

作成したIssueをこのマイルストーンに割り当て：

```bash
gh issue edit <issue-number> --milestone "Security Hardening v1.1"
```

---

## 🔄 Issue作成後のワークフロー

1. **優先度順に対応**
   - Critical Issues (1, 2) を最優先で対応
   - Medium Issues (3, 4) を次に対応

2. **ブランチ作成**
   ```bash
   git checkout -b security/fix-encryption-issue-XXX
   ```

3. **実装 & テスト**
   - 各Issueの「実装タスク」チェックリストに従って作業
   - ユニットテストを必ず作成

4. **Pull Request作成**
   ```bash
   gh pr create \
     --title "fix: XOR暗号をAES-GCMに置き換え (closes #XXX)" \
     --body "Fixes #XXX\n\n## 変更内容\n- ConfigEncryptionクラスをAES-GCM実装に置き換え\n- ユニットテスト追加"
   ```

5. **レビュー & マージ**
   - セキュリティ担当者によるコードレビュー
   - 全テストが通過することを確認
   - mainブランチにマージ

6. **検証 & クローズ**
   - 本番環境で動作確認
   - Issueをクローズ

---

## 📝 テンプレート例

各Issueの本文は `SECURITY_ISSUES.md` から直接コピーできますが、必要に応じて以下のセクションを追加：

```markdown
## 影響範囲
- [ ] Android
- [ ] iOS
- [ ] Web
- [ ] Desktop

## 検証手順
1. XXXを実行
2. YYYを確認
3. ZZZが期待通り動作することを確認

## 完了条件
- [ ] 実装完了
- [ ] ユニットテスト作成
- [ ] コードレビュー完了
- [ ] 本番環境で動作確認
```

---

## 🎯 まとめ

1. `SECURITY_ISSUES.md` の内容を基にGitHub Issueを作成
2. 適切なラベルとマイルストーンを設定
3. 優先度（Critical → Medium）に従って対応
4. 各Issueの完了後、セキュリティ監査を再実施

---

**作成日**: 2025-11-28
**更新日**: 2025-11-28
