/**
 * HotPepper API プロキシサーバー (Cloudflare Workers) - シンプル版
 */

function getCorsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders();
    
    // CORS プリフライトリクエスト対応
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: corsHeaders,
      });
    }

    // POST /api/hotpepper/search エンドポイント
    if (request.method === 'POST' && new URL(request.url).pathname === '/api/hotpepper/search') {
      return handleSearch(request, env, corsHeaders);
    }

    // 404 レスポンス
    return new Response('Not Found', {
      status: 404,
      headers: corsHeaders,
    });
  },
};

async function handleSearch(request, env, corsHeaders) {
  try {
    // パラメータ取得
    const requestBody = await request.json();
    
    // モックレスポンスを返す（テスト用）
    const mockResponse = {
      results: {
        shop: [
          {
            id: 'mock_001',
            name: 'テスト中華店',
            address: '東京都新宿区西新宿1-1-1',
            lat: '35.6812',
            lng: '139.7671',
            genre: { name: '中華料理' },
            budget: { name: '～1000円' },
            access: 'JR新宿駅徒歩5分',
            catch: 'テスト用の中華料理店',
            urls: { pc: 'http://example.com', mobile: 'http://m.example.com' },
            photo: { mobile: { l: 'http://example.com/photo.jpg' } },
            open: '11:00',
            close: '22:00'
          }
        ],
        results_available: 1,
        results_returned: 1,
        results_start: 1
      }
    };

    return new Response(JSON.stringify(mockResponse), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: `Server error: ${error.message}` }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });
  }
}