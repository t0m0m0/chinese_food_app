# Chinese Food App API Proxy Server

Cloudflare Workersベースのプロキシサーバーで、APIキーのセキュリティを強化します。

## セキュリティ機能

- **APIキー保護**: サーバーサイドでAPIキーを管理
- **CORS制御**: 許可されたオリジンのみアクセス可能
- **レート制限**: API濫用防止
- **リクエスト検証**: パラメータの妥当性チェック

## セットアップ

### 1. 依存関係のインストール

```bash
cd proxy-server
npm install
```

### 2. KV Namespace の作成

レート制限機能のためのKVストレージを作成します：

```bash
# 本番用KV Namespace作成
wrangler kv:namespace create "RATE_LIMIT_KV"
# 出力例: { binding = "RATE_LIMIT_KV", id = "abc123456789def" }

# プレビュー用KV Namespace作成
wrangler kv:namespace create "RATE_LIMIT_KV" --preview
# 出力例: { binding = "RATE_LIMIT_KV", preview_id = "def987654321abc" }
```

作成したIDを`wrangler.toml`に設定：

```toml
[[kv_namespaces]]
binding = "RATE_LIMIT_KV"
id = "abc123456789def"  # 実際のIDに置き換え
preview_id = "def987654321abc"  # 実際のIDに置き換え

[[env.production.kv_namespaces]]
binding = "RATE_LIMIT_KV"
id = "production_kv_id_here"  # 本番用IDに置き換え
```

### 3. APIキーの設定

```bash
# HotPepper API Key
wrangler secret put HOTPEPPER_API_KEY

# Google Maps API Key（将来使用）
wrangler secret put GOOGLE_MAPS_API_KEY
```

### 4. 開発サーバー起動

```bash
npm run dev
```

### 5. 本番デプロイ

```bash
npm run deploy:production
```

## API エンドポイント

### HotPepper 店舗検索
`POST /api/hotpepper/search`

```json
{
  "lat": 35.6917,
  "lng": 139.7006,
  "address": "東京都新宿区",
  "keyword": "中華",
  "range": 3,
  "count": 20,
  "start": 1
}
```

### ヘルスチェック
`GET /health`

## セキュリティ設定

### CORS設定
- 開発環境: `ALLOWED_ORIGINS="*"`
- 本番環境: `ALLOWED_ORIGINS="https://your-app-domain.com"`

### レート制限
- HotPepper API: 60リクエスト/時間 (Cloudflare KV使用)
- Google Maps API: 100リクエスト/時間 (将来実装)

**KV Namespaceが設定されていない場合、レート制限は無効化されます（開発環境用）**

## 環境変数

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `HOTPEPPER_API_KEY` | HotPepper API キー | ✅ |
| `GOOGLE_MAPS_API_KEY` | Google Maps API キー | ⚪ |
| `ALLOWED_ORIGINS` | 許可するオリジン | ✅ |
| `RATE_LIMIT_KV` | レート制限用KV Namespace | ⚪ |

## トラブルシューティング

### API Key Not Found
```bash
wrangler secret put HOTPEPPER_API_KEY
# APIキーを入力
```

### CORS エラー
`wrangler.toml`の`ALLOWED_ORIGINS`を確認

### Rate Limit
429エラーが発生した場合は、リクエスト頻度を調整してください。

### KV Namespace エラー
```bash
# KV Namespaceが見つからない場合
wrangler kv:namespace list
# 既存のNamespaceを確認し、wrangler.tomlのIDを更新
```