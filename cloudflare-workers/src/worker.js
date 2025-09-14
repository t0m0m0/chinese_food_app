/**
 * HotPepper API プロキシサーバー (Cloudflare Workers)
 * 
 * セキュリティ向上のため、APIキーをサーバーサイドで管理し、
 * フロントエンドからの安全なAPI呼び出しを可能にします。
 */

/**
 * 環境別CORS設定
 * 本番環境では特定ドメインのみ許可、開発環境では柔軟に対応
 */
function getCorsHeaders(request, env) {
  const origin = request.headers.get('Origin');
  
  // 本番環境での許可ドメインリスト
  const allowedOrigins = [
    'https://chinese-food-app.vercel.app',
    'https://chinese-food-app.netlify.app', 
    'https://your-production-domain.com'
  ];
  
  // 開発環境での許可ドメインパターン
  const developmentPatterns = [
    /^https?:\/\/localhost(:\d+)?$/,
    /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
    /^https?:\/\/.+\.ngrok\.io$/,
    /^https?:\/\/.+\.vercel\.app$/
  ];
  
  let allowedOrigin = '*';
  
  if (env.ENVIRONMENT === 'production') {
    // 本番環境: 許可リストのドメインのみ
    if (origin && allowedOrigins.includes(origin)) {
      allowedOrigin = origin;
    } else {
      allowedOrigin = allowedOrigins[0]; // デフォルトを最初のドメインに
    }
  } else {
    // 開発・ステージング環境: パターンマッチングで柔軟に対応
    if (origin && (allowedOrigins.includes(origin) || 
        developmentPatterns.some(pattern => pattern.test(origin)))) {
      allowedOrigin = origin;
    } else {
      allowedOrigin = '*'; // 開発時は緩い設定
    }
  }
  
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400', // 24時間キャッシュ
  };
}

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders(request, env);
    
    // CORS プリフライトリクエスト対応
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: corsHeaders,
      });
    }

    // POST /api/hotpepper/search エンドポイント
    if (request.method === 'POST' && new URL(request.url).pathname === '/api/hotpepper/search') {
      return handleHotpepperSearch(request, env, corsHeaders);
    }

    // 404 レスポンス
    return new Response('Not Found', {
      status: 404,
      headers: corsHeaders,
    });
  },
};

/**
 * HotPepper API検索リクエストの処理
 */
async function handleHotpepperSearch(request, env, corsHeaders) {
  try {
    console.log('🔍 [Worker] handleHotpepperSearch started');
    
    // 環境変数チェック
    if (!env.HOTPEPPER_API_KEY) {
      console.error('❌ [Worker] HOTPEPPER_API_KEY not found');
      return createErrorResponse(500, 'API key not configured', corsHeaders);
    }
    console.log('✅ [Worker] HOTPEPPER_API_KEY found');

    // リクエストボディの解析
    console.log('📥 [Worker] Parsing request body...');
    const requestBody = await request.json();
    console.log('📋 [Worker] Request body:', JSON.stringify(requestBody));
    const { lat, lng, address, keyword, range, count, start } = requestBody;

    // パラメータバリデーション
    console.log('🔍 [Worker] Validating parameters...');
    const validationError = validateSearchParams({ lat, lng, address, range, count, start });
    if (validationError) {
      console.error('❌ [Worker] Validation error:', validationError);
      return createErrorResponse(400, validationError, corsHeaders);
    }
    console.log('✅ [Worker] Parameters valid');

    // HotPepper API呼び出し
    console.log('🌐 [Worker] Calling HotPepper API...');
    const hotpepperResponse = await callHotpepperApi({
      lat, lng, address, keyword, range, count, start
    }, env.HOTPEPPER_API_KEY);
    console.log('✅ [Worker] HotPepper API response received');

    // レスポンス変換
    console.log('🔄 [Worker] Transforming response...');
    const transformedResponse = transformHotpepperResponse(hotpepperResponse);
    console.log('✅ [Worker] Response transformed, shops:', transformedResponse.shops.length);

    return new Response(JSON.stringify(transformedResponse), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });

  } catch (error) {
    console.error('❌ [Worker] Error in handleHotpepperSearch:', error);
    console.error('📍 [Worker] Error stack:', error.stack);
    return createErrorResponse(500, `Internal server error: ${error.message}`, corsHeaders);
  }
}

/**
 * 検索パラメータのバリデーション
 */
function validateSearchParams({ lat, lng, address, range, count, start }) {
  // 緯度・経度の検証
  if (lat !== undefined && (lat < -90.0 || lat > 90.0)) {
    return '緯度は-90.0から90.0の範囲で指定してください';
  }
  if (lng !== undefined && (lng < -180.0 || lng > 180.0)) {
    return '経度は-180.0から180.0の範囲で指定してください';
  }

  // 検索範囲の検証
  if (range < 1 || range > 5) {
    return '検索範囲は1から5の間で指定してください';
  }

  // 取得件数の検証
  if (count < 1 || count > 100) {
    return '取得件数は1から100の間で指定してください';
  }

  // 検索開始位置の検証
  if (start < 1) {
    return '検索開始位置は1以上で指定してください';
  }

  // 住所または緯度経度のいずれかが必要
  const hasAddress = address && address.trim().length > 0;
  const hasLatLng = lat !== undefined && lng !== undefined;
  if (!hasAddress && !hasLatLng) {
    return '住所または緯度経度を指定してください';
  }

  return null; // エラーなし
}

/**
 * HotPepper API呼び出し
 */
async function callHotpepperApi(params, apiKey) {
  const { lat, lng, address, keyword, range, count, start } = params;

  // HotPepper API URL構築
  const apiUrl = new URL('https://webservice.recruit.co.jp/hotpepper/gourmet/v1/');
  apiUrl.searchParams.set('key', apiKey);
  apiUrl.searchParams.set('format', 'json');
  apiUrl.searchParams.set('keyword', keyword || '中華');
  apiUrl.searchParams.set('range', range.toString());
  apiUrl.searchParams.set('count', count.toString());
  apiUrl.searchParams.set('start', start.toString());

  // 位置情報パラメータ
  if (lat !== undefined && lng !== undefined) {
    apiUrl.searchParams.set('lat', lat.toString());
    apiUrl.searchParams.set('lng', lng.toString());
  }
  if (address) {
    apiUrl.searchParams.set('address', address);
  }

  console.log('🌐 [Worker] HotPepper API URL:', apiUrl.toString());

  // API呼び出し
  const response = await fetch(apiUrl.toString(), {
    method: 'GET',
    headers: {
      'User-Agent': 'ChineseFoodApp/1.0',
    },
  });

  console.log('📡 [Worker] HotPepper API status:', response.status);

  if (!response.ok) {
    const errorText = await response.text();
    console.error('❌ [Worker] HotPepper API error response:', errorText);
    throw new Error(`HotPepper API error: ${response.status} ${response.statusText} - ${errorText}`);
  }

  const jsonResponse = await response.json();
  console.log('📊 [Worker] HotPepper API response type:', typeof jsonResponse);
  return jsonResponse;
}

/**
 * HotPepper APIレスポンスの変換
 */
function transformHotpepperResponse(hotpepperResponse) {
  const { results } = hotpepperResponse;

  // エラーレスポンスの場合
  if (results.error) {
    throw new Error(`HotPepper API error: ${results.error[0].message}`);
  }

  // 店舗データの変換
  const shops = (results.shop || []).map(shop => ({
    id: shop.id,
    name: shop.name,
    address: shop.address,
    lat: parseFloat(shop.lat),
    lng: parseFloat(shop.lng),
    genre: shop.genre?.name || null,
    budget: shop.budget?.average || null,
    access: shop.access || null,
    catch_: shop.catch || null,
    photo: shop.photo?.pc?.l || null,
  }));

  return {
    shops,
    resultsAvailable: parseInt(results.results_available) || 0,
    resultsReturned: parseInt(results.results_returned) || 0,
    resultsStart: parseInt(results.results_start) || 1,
  };
}

/**
 * エラーレスポンス作成
 */
function createErrorResponse(status, message, corsHeaders) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}