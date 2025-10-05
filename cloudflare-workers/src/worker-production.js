/**
 * HotPepper API プロキシサーバー (Cloudflare Workers) - 本番版
 */

function getCorsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
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

    // GET /api/hotpepper/search エンドポイント
    if (request.method === 'GET' && new URL(request.url).pathname === '/api/hotpepper/search') {
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
    console.log('🔍 [Worker] Search request started');

    // 環境変数チェック
    if (!env.HOTPEPPER_API_KEY) {
      console.error('❌ [Worker] HOTPEPPER_API_KEY not found');
      return createErrorResponse(500, 'API key not configured', corsHeaders);
    }
    console.log('✅ [Worker] HOTPEPPER_API_KEY found');

    // クエリパラメータ取得
    const url = new URL(request.url);

    // 緯度・経度のパース（NaNチェック付き）
    const latParam = url.searchParams.get('lat');
    const lngParam = url.searchParams.get('lng');
    const lat = latParam ? parseFloat(latParam) : undefined;
    const lng = lngParam ? parseFloat(lngParam) : undefined;

    // NaNチェック
    if (lat !== undefined && isNaN(lat)) {
      return createErrorResponse(400, '緯度の値が不正です', corsHeaders);
    }
    if (lng !== undefined && isNaN(lng)) {
      return createErrorResponse(400, '経度の値が不正です', corsHeaders);
    }

    const address = url.searchParams.get('address') || undefined;
    const keyword = url.searchParams.get('keyword') || '中華';

    // 数値パラメータ（NaNチェック付き）
    const range = parseInt(url.searchParams.get('range') || '3', 10);
    const count = parseInt(url.searchParams.get('count') || '20', 10);
    const start = parseInt(url.searchParams.get('start') || '1', 10);

    if (isNaN(range) || isNaN(count) || isNaN(start)) {
      return createErrorResponse(400, 'パラメータの値が不正です', corsHeaders);
    }

    console.log('📋 [Worker] Query params:', JSON.stringify({ lat, lng, address, keyword, range, count, start }));

    // パラメータバリデーション
    const validationError = validateParams({ lat, lng, address, range, count, start });
    if (validationError) {
      console.error('❌ [Worker] Validation error:', validationError);
      return createErrorResponse(400, validationError, corsHeaders);
    }

    // HotPepper API呼び出し
    console.log('🌐 [Worker] Calling HotPepper API...');
    const hotpepperResponse = await callHotpepperApi({
      lat, lng, address, keyword, range, count, start
    }, env.HOTPEPPER_API_KEY);
    
    console.log('📊 [Worker] HotPepper response received');

    // レスポンス変換
    const transformedResponse = transformResponse(hotpepperResponse);
    console.log('✅ [Worker] Response transformed, shops:', transformedResponse.results.shop.length);

    return new Response(JSON.stringify(transformedResponse), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });

  } catch (error) {
    console.error('❌ [Worker] Error:', error);
    return createErrorResponse(500, `Server error: ${error.message}`, corsHeaders);
  }
}

function validateParams({ lat, lng, address, range, count, start }) {
  // NaNチェック（念のため）
  if (lat !== undefined && isNaN(lat)) {
    return '緯度の値が不正です';
  }
  if (lng !== undefined && isNaN(lng)) {
    return '経度の値が不正です';
  }
  if (isNaN(range) || isNaN(count) || isNaN(start)) {
    return 'パラメータの値が不正です';
  }

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

  console.log('🌐 [Worker] HotPepper API URL constructed');

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
    console.error('❌ [Worker] HotPepper API error:', errorText);
    throw new Error(`HotPepper API error: ${response.status} - ${errorText}`);
  }

  const jsonResponse = await response.json();
  return jsonResponse;
}

function transformResponse(hotpepperResponse) {
  try {
    console.log('🔄 [Worker] Transforming response...');
    console.log('📊 [Worker] Response type:', typeof hotpepperResponse);
    
    if (!hotpepperResponse || !hotpepperResponse.results) {
      console.error('❌ [Worker] Invalid response structure:', hotpepperResponse);
      throw new Error('Invalid HotPepper API response structure');
    }
    
    const { results } = hotpepperResponse;
    console.log('📋 [Worker] Results keys:', Object.keys(results));

    // エラーレスポンスの場合
    if (results.error) {
      console.error('❌ [Worker] HotPepper API error:', results.error);
      throw new Error(`HotPepper API error: ${results.error[0].message}`);
    }

    console.log('🏪 [Worker] Shop count:', (results.shop || []).length);
    console.log('📊 [Worker] Results available:', results.results_available);

    const shops = (results.shop || []).map((shop, index) => {
      console.log(`🏪 [Worker] Processing shop ${index}:`, shop?.name);
      return {
        id: shop?.id || '',
        name: shop?.name || '',
        address: shop?.address || '',
        lat: shop?.lat || null,
        lng: shop?.lng || null,
        genre: shop?.genre ? { name: shop.genre.name || null } : null,
        budget: shop?.budget ? { name: shop.budget.name || null } : null,
        access: shop?.access || null,
        catch: shop?.catch || null,
        urls: shop?.urls ? {
          pc: shop.urls.pc || null,
          mobile: shop.urls.mobile || null
        } : null,
        photo: shop?.photo ? {
          mobile: shop.photo.mobile ? {
            l: shop.photo.mobile.l || null
          } : null
        } : null,
        open: shop?.open || null,
        close: shop?.close || null,
      };
    });

    // HotPepper API互換構造でレスポンス作成
    const finalResponse = {
      results: {
        shop: shops,
        results_available: parseInt(results.results_available?.toString() || '0') || 0,
        results_returned: parseInt(results.results_returned?.toString() || '0') || 0,
        results_start: parseInt(results.results_start?.toString() || '1') || 1,
      }
    };
    
    console.log('✅ [Worker] Transform completed, final shop count:', finalResponse.results.shop.length);
    return finalResponse;
    
  } catch (error) {
    console.error('❌ [Worker] Transform error:', error);
    console.error('📍 [Worker] Error stack:', error.stack);
    throw error;
  }
}

function createErrorResponse(status, message, corsHeaders) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}