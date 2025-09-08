# HotPepper API Proxy Server (Cloudflare Workers)

町中華アプリ用のセキュアなAPIプロキシサーバーです。

## 🎯 目的

- **セキュリティ向上**: HotPepper APIキーをサーバーサイドで安全管理
- **CORS対応**: フロントエンドからの安全なクロスオリジンアクセス
- **レート制限**: API呼び出し制限の一元管理
- **エラーハンドリング**: 統一されたエラーレスポンス

## 📋 前提条件

- Cloudflareアカウント
- HotPepper API キー
- Node.js 18+

## 🚀 セットアップ手順

### 1. 依存関係のインストール

```bash
cd cloudflare-workers
npm install
```

### 2. Cloudflareにログイン

```bash
npx wrangler login
```

### 3. 環境変数設定

Cloudflareダッシュボードまたはコマンドラインで設定：

```bash
# HotPepper APIキーを設定
npx wrangler secret put HOTPEPPER_API_KEY
# プロンプトでAPIキーを入力
```

### 4. ローカル開発

```bash
npm run dev
```

ローカル開発サーバー: `http://localhost:8787`

### 5. デプロイ

```bash
# 開発環境
npm run deploy

# 本番環境  
npm run deploy:production
```

## 📡 API仕様

### エンドポイント

```
POST /api/hotpepper/search
```

### リクエスト例

```json
{
  "lat": 35.6917,
  "lng": 139.7006,
  "keyword": "中華",
  "range": 3,
  "count": 20,
  "start": 1
}
```

### レスポンス例

```json
{
  "shops": [
    {
      "id": "J001234567",
      "name": "町中華 龍華楼",
      "address": "東京都新宿区西新宿1-1-1",
      "lat": 35.6917,
      "lng": 139.7006,
      "genre": "中華料理",
      "budget": "～1000円",
      "access": "JR新宿駅徒歩5分",
      "catch_": "昔ながらの町中華！",
      "photo": "https://imgfp.hotp.jp/example.jpg"
    }
  ],
  "resultsAvailable": 15,
  "resultsReturned": 1,
  "resultsStart": 1
}
```

## 🔧 環境変数

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `HOTPEPPER_API_KEY` | HotPepper API キー | ✅ |

## 🛠️ 開発コマンド

```bash
# ローカル開発サーバー起動
npm run dev

# デプロイ（開発環境）
npm run deploy

# デプロイ（本番環境）
npm run deploy:production

# ログ監視
npm run tail
```

## 📊 監視・ログ

Cloudflareダッシュボードで以下を監視できます：

- リクエスト数・エラー率
- レスポンス時間
- CPU・メモリ使用量
- リアルタイムログ

## 🔒 セキュリティ

### CORS設定

現在は `Access-Control-Allow-Origin: *` ですが、本番環境では特定ドメインに制限：

```javascript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://your-app-domain.com',
  // ...
};
```

### レート制限

必要に応じてWorkersでレート制限を実装：

```javascript
// リクエスト制限例（1分間に60リクエスト）
const rateLimiter = new Map();
```

## 🐛 トラブルシューティング

### よくあるエラー

1. **401 Unauthorized**
   - HotPepper APIキーを確認
   - 環境変数設定を確認

2. **CORS エラー**
   - フロントエンドのオリジンを確認
   - CORS設定を確認

3. **500 Internal Server Error**
   - Cloudflare Workersログを確認
   - HotPepper API応答を確認

### デバッグ

```bash
# リアルタイムログ監視
npm run tail

# ローカルデバッグ
npm run dev
```

## 📈 パフォーマンス

- **レイテンシ**: 平均 < 100ms（東京リージョン）
- **可用性**: 99.99%（Cloudflareインフラ）
- **スケーラビリティ**: 自動スケール対応

## 💰 コスト概算

| 月間リクエスト数 | 月額料金 |
|------------------|----------|
| 100K以下 | $0（無料枠） |
| 1M | $0.50 |
| 10M | $5.00 |

## 🔄 アップデート

コードを更新してデプロイ：

```bash
# コード修正後
npm run deploy
```

数秒で世界中に反映されます。