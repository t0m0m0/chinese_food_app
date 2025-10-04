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
    let hotpepperResponse;
    
    // 開発中はテスト用のモックレスポンスを使用（API問題を回避）
    if (env.USE_MOCK_RESPONSE === 'true') {
      console.log('🧪 [Worker] Using mock response for testing');
      hotpepperResponse = {
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
    } else {
      hotpepperResponse = await callHotpepperApi({
        lat, lng, address, keyword, range, count, start
      }, env.HOTPEPPER_API_KEY);
    }
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
 * アプリ側のHotpepperStoreModel.fromJsonと完全互換な構造で変換
 */
function transformHotpepperResponse(hotpepperResponse) {
  try {
    console.log('🔄 [Worker] Raw HotPepper response type:', typeof hotpepperResponse);
    console.log('🔄 [Worker] Raw HotPepper response keys:', Object.keys(hotpepperResponse || {}));
    
    if (!hotpepperResponse || !hotpepperResponse.results) {
      throw new Error('Invalid HotPepper API response structure');
    }
    
    const { results } = hotpepperResponse;
    console.log('📋 [Worker] Results keys:', Object.keys(results || {}));

    // エラーレスポンスの場合
    if (results.error) {
      console.error('❌ [Worker] HotPepper API error:', results.error);
      throw new Error(`HotPepper API error: ${results.error[0].message}`);
    }

    console.log('📊 [Worker] Results available:', results.results_available);
    console.log('📊 [Worker] Results returned:', results.results_returned);
    console.log('📊 [Worker] Results start:', results.results_start);
    console.log('📊 [Worker] Shop count:', (results.shop || []).length);

    // 店舗データの変換 - アプリ側の期待構造と完全一致
    const shops = (results.shop || []).map((shop, index) => {
      try {
        console.log(`🏪 [Worker] Processing shop ${index}:`, shop?.name || 'Unknown');
        return {
          id: shop?.id || '',
          name: shop?.name || '',
          address: shop?.address || '',
          lat: shop?.lat || null,  // 文字列のまま（アプリ側でdouble.tryParse）
          lng: shop?.lng || null,  // 文字列のまま（アプリ側でdouble.tryParse）
          
          // アプリ側が期待するオブジェクト構造を維持
          genre: shop?.genre ? { name: shop.genre.name || null } : null,
          budget: shop?.budget ? { name: shop.budget.name || null } : null,
          
          access: shop?.access || null,
          catch: shop?.catch || null,  // catch_ではなくcatch
          
          // URLsオブジェクト構造を維持（安全なアクセス）
          urls: shop?.urls ? {
            pc: shop.urls.pc || null,
            mobile: shop.urls.mobile || null
          } : null,
          
          // photoオブジェクト構造を維持（安全なアクセス）
          photo: shop?.photo ? {
            mobile: shop.photo.mobile ? {
              l: shop.photo.mobile.l || null
            } : null
          } : null,
          
          open: shop?.open || null,
          close: shop?.close || null,
        };
      } catch (shopError) {
        console.error(`❌ [Worker] Error processing shop ${index}:`, shopError);
        // 最小限のデータを返す
        return {
          id: shop?.id || `error_${index}`,
          name: shop?.name || 'Error parsing shop',
          address: shop?.address || '',
          lat: null,
          lng: null,
          genre: null,
          budget: null,
          access: null,
          catch: null,
          urls: null,
          photo: null,
          open: null,
          close: null,
        };
      }
    });

    // HotPepper API互換の構造でレスポンスを作成
    const finalResponse = {
      results: {
        shop: shops,
        results_available: parseInt(results.results_available?.toString() || '0') || 0,
        results_returned: parseInt(results.results_returned?.toString() || '0') || 0,
        results_start: parseInt(results.results_start?.toString() || '1') || 1,
      }
    };
    
    console.log('✅ [Worker] Final response prepared with', shops ? shops.length : 0, 'shops');
    
    return finalResponse;
    
  } catch (transformError) {
    console.error('❌ [Worker] Error in transformHotpepperResponse:', transformError);
    console.error('📍 [Worker] Transform error stack:', transformError.stack);
    throw transformError;
  }
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