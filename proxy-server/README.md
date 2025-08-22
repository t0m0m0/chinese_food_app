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

### 2. APIキーの設定

```bash
# HotPepper API Key
wrangler secret put HOTPEPPER_API_KEY

# Google Maps API Key（将来使用）
wrangler secret put GOOGLE_MAPS_API_KEY
```

### 3. 開発サーバー起動

```bash
npm run dev
```

### 4. 本番デプロイ

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
- HotPepper API: 60リクエスト/分
- Google Maps API: 100リクエスト/分

## 環境変数

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `HOTPEPPER_API_KEY` | HotPepper API キー | ✅ |
| `GOOGLE_MAPS_API_KEY` | Google Maps API キー | ⚪ |
| `ALLOWED_ORIGINS` | 許可するオリジン | ✅ |

## トラブルシューティング

### API Key Not Found
```bash
wrangler secret put HOTPEPPER_API_KEY
# APIキーを入力
```

### CORS エラー
`wrangler.toml`の`ALLOWED_ORIGINS`を確認

### Rate Limit
429エラーが発生した場合は、リクエスト頻度を調整