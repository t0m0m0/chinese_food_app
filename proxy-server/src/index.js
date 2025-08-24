/**
 * Cloudflare Worker for Chinese Food App API Proxy
 * 
 * セキュリティ機能:
 * - APIキーをサーバーサイドで管理
 * - CORS制御
 * - レート制限
 * - リクエスト検証
 */

// API endpoints configuration
const API_ENDPOINTS = {
  HOTPEPPER: 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/',
  GOOGLE_MAPS: 'https://maps.googleapis.com/maps/api/'
};

// Rate limiting configuration (requests per minute)
const RATE_LIMITS = {
  HOTPEPPER: 60,  // HotPepper API: 5 requests/second = 300/minute, but we're conservative
  GOOGLE_MAPS: 100
};

export default {
  async fetch(request, env, ctx) {
    return await handleRequest(request, env);
  }
};

async function handleRequest(request, env) {
  // CORS preflight
  if (request.method === 'OPTIONS') {
    return handleCors(request, env);
  }

  try {
    // CORS check
    if (!isAllowedOrigin(request, env)) {
      return new Response('Unauthorized origin', { status: 403 });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // Route API requests
    if (path.startsWith('/api/hotpepper/')) {
      return await handleHotPepperAPI(request, env);
    } else if (path.startsWith('/api/google-maps/')) {
      return await handleGoogleMapsAPI(request, env);
    } else if (path === '/health') {
      return new Response('OK', { status: 200 });
    } else {
      return new Response('Not Found', { status: 404 });
    }
  } catch (error) {
    console.error('Proxy error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
}

/**
 * HotPepper API プロキシハンドラー
 */
async function handleHotPepperAPI(request, env) {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Rate limiting check
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  if (await isRateLimited(clientIP, 'hotpepper', RATE_LIMITS.HOTPEPPER, env)) {
    return new Response('Rate limit exceeded', { status: 429 });
  }

  try {
    const body = await request.json();
    const { lat, lng, address, keyword, range = 3, count = 20, start = 1 } = body;

    // パラメータ検証
    if (!validateHotPepperParams({ lat, lng, address, keyword, range, count, start })) {
      return new Response('Invalid parameters', { status: 400 });
    }

    // API call with server-side API key
    const apiKey = env.HOTPEPPER_API_KEY;
    if (!apiKey) {
      throw new Error('HotPepper API key not configured');
    }

    const queryParams = new URLSearchParams({
      key: apiKey,
      format: 'json',
      count: count.toString(),
      start: start.toString(),
      range: range.toString(),
      keyword: keyword || '中華'
    });

    if (lat && lng) {
      queryParams.append('lat', lat.toString());
      queryParams.append('lng', lng.toString());
    }

    if (address) {
      queryParams.append('address', address);
    }

    const apiUrl = `${API_ENDPOINTS.HOTPEPPER}?${queryParams}`;
    const response = await fetch(apiUrl);
    
    if (!response.ok) {
      throw new Error(`HotPepper API error: ${response.status}`);
    }

    const data = await response.json();
    
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...getCorsHeaders(request, env)
      }
    });

  } catch (error) {
    console.error('HotPepper API error:', error);
    return new Response('API request failed', { status: 500 });
  }
}

/**
 * Google Maps API プロキシハンドラー（将来拡張用）
 */
async function handleGoogleMapsAPI(request, env) {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Rate limiting check
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  if (await isRateLimited(clientIP, 'google-maps', RATE_LIMITS.GOOGLE_MAPS, env)) {
    return new Response('Rate limit exceeded', { status: 429 });
  }

  // Google Maps API proxy implementation
  // Currently, this app uses Google Maps SDK directly, so this is for future use
  return new Response('Google Maps proxy not implemented yet', { status: 501 });
}

/**
 * HotPepper APIパラメータ検証
 */
function validateHotPepperParams({ lat, lng, address, keyword, range, count, start }) {
  // 緯度経度の検証
  if (lat !== undefined && (lat < -90 || lat > 90)) return false;
  if (lng !== undefined && (lng < -180 || lng > 180)) return false;
  
  // 範囲、件数、開始位置の検証
  if (range < 1 || range > 5) return false;
  if (count < 1 || count > 100) return false;
  if (start < 1) return false;
  
  // 住所または緯度経度のいずれかが必要
  if (!address && !(lat && lng)) return false;
  
  return true;
}

/**
 * CORS設定
 */
function isAllowedOrigin(request, env) {
  const origin = request.headers.get('Origin');
  const allowedOrigins = env.ALLOWED_ORIGINS;
  
  if (allowedOrigins === '*') return true;
  if (!origin) return false;
  
  return allowedOrigins.split(',').includes(origin);
}

function getCorsHeaders(request, env) {
  const origin = request.headers.get('Origin');
  const allowedOrigins = env.ALLOWED_ORIGINS;
  
  if (allowedOrigins === '*') {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }
  
  if (origin && allowedOrigins.split(',').includes(origin)) {
    return {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }
  
  return {};
}

function handleCors(request, env) {
  return new Response(null, {
    status: 200,
    headers: getCorsHeaders(request, env)
  });
}

/**
 * レート制限チェック（本番対応実装）
 * Cloudflare KVを使用したクライアントIP別レート制限
 */
async function isRateLimited(clientIP, apiType, limit, env) {
  // 開発環境では制限を適用しない
  if (!env.RATE_LIMIT_KV) {
    return false;
  }

  try {
    const key = `rate_limit:${clientIP}:${apiType}`;
    const now = Math.floor(Date.now() / 1000); // Unix timestamp
    const windowSize = 3600; // 1時間のウィンドウ
    
    // KVから現在のリクエスト数を取得
    const currentData = await env.RATE_LIMIT_KV.get(key, { type: 'json' });
    
    let requestCount = 0;
    let windowStart = now;
    
    if (currentData) {
      // 既存データがウィンドウ内の場合は継続、古い場合はリセット
      if (now - currentData.windowStart < windowSize) {
        requestCount = currentData.count;
        windowStart = currentData.windowStart;
      }
    }
    
    // レート制限チェック
    if (requestCount >= limit) {
      console.log(`Rate limit exceeded for ${clientIP}: ${requestCount}/${limit}`);
      return true;
    }
    
    // リクエスト数を更新してKVに保存
    const newData = {
      count: requestCount + 1,
      windowStart: windowStart,
      lastRequest: now
    };
    
    // TTLを設定してKVに保存（ウィンドウサイズ + 少し余裕）
    await env.RATE_LIMIT_KV.put(key, JSON.stringify(newData), {
      expirationTtl: windowSize + 300
    });
    
    return false;
    
  } catch (error) {
    console.error('Rate limiting error:', error);
    // エラーが発生した場合は制限を適用しない（フェイルオープン）
    return false;
  }
}