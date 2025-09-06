# エラーハンドリングガイドライン

## 概要

このドキュメントは、統一例外処理システムの使用方法と開発ガイドラインを説明します。

## 統一例外システムの目的

- **一貫性**: 全てのエラーを統一的な方法で処理
- **保守性**: 重複を排除し、エラー処理ロジックを一元化
- **ユーザビリティ**: 分かりやすいエラーメッセージをユーザーに提供
- **デバッグ効率**: 構造化されたログでデバッグを支援

## 基本アーキテクチャ

```
BaseException (基底クラス)
├── UnifiedNetworkException (ネットワーク関連)
├── UnifiedSecurityException (セキュリティ関連) 
├── ValidationException (入力検証)
├── DatabaseException (データベース)
├── LocationException (位置情報)
└── AppException (汎用ラッパー)
```

## 使用方法

### 1. 基本的な例外の投げ方

```dart
// 統一例外システムをインポート
import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';

// ネットワークエラー
throw UnifiedNetworkException.api('APIエラーが発生しました', statusCode: 400);

// セキュリティエラー
throw UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');

// タイムアウトエラー
throw UnifiedNetworkException.timeout('リクエストがタイムアウトしました');
```

### 2. 統一エラーハンドラーの使用

```dart
import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';

final handler = UnifiedExceptionHandler();

// 同期処理
final result = handler.execute(() {
  // 例外が発生する可能性のある処理
  return riskyOperation();
});

if (result.isSuccess) {
  print('成功: ${result.data}');
} else {
  print('エラー: ${result.userMessage}');
}

// 非同期処理
final asyncResult = await handler.executeAsync(() async {
  return await riskyAsyncOperation();
});
```

### 3. try-catch使用時

```dart
try {
  final data = await riskyOperation();
  return handler.success(data);
} catch (e, stackTrace) {
  return handler.handle(e, stackTrace);
}
```

## 例外種別とファクトリコンストラクタ

### UnifiedNetworkException

```dart
// API エラー
UnifiedNetworkException.api('API処理に失敗', statusCode: 500);

// HTTP エラー
UnifiedNetworkException.http('Not Found', statusCode: 404);

// タイムアウト
UnifiedNetworkException.timeout('接続がタイムアウトしました');

// 接続エラー
UnifiedNetworkException.connection('ネットワークに接続できません');
```

### UnifiedSecurityException

```dart
// APIキー未設定
UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');

// APIキーアクセスエラー
UnifiedSecurityException.apiKeyAccess('HOTPEPPER_API_KEY', 'アクセス権限がありません');

// セキュアストレージエラー
UnifiedSecurityException.secureStorage('read', 'データにアクセスできません');

// 環境設定エラー
UnifiedSecurityException.environmentConfig('設定ファイルが見つかりません');
```

## 重要度レベル (ExceptionSeverity)

| レベル | 用途 | 例 |
|--------|------|-----|
| `low` | 情報・軽微な問題 | キャッシュ失効 |
| `medium` | 通常のエラー | バリデーション失敗 |
| `high` | 重要なエラー | API通信エラー |
| `critical` | アプリ動作に影響 | データベース接続失敗 |

## 移行ガイド

### 従来の例外から統一例外への移行

```dart
// 従来（非推奨）
throw NetworkException('Network error', statusCode: 500);
throw ApiException('API error', statusCode: 400);

// 統一例外（推奨）
throw UnifiedNetworkException.http('Network error', statusCode: 500);
throw UnifiedNetworkException.api('API error', statusCode: 400);
```

```dart
// 従来（非推奨）
throw SecurityException('Security error');
throw APIKeyNotFoundException('HOTPEPPER_API_KEY');

// 統一例外（推奨）
throw UnifiedSecurityException('Security error');
throw UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');
```

## ベストプラクティス

### DO ✅

1. **統一例外システムを使用**:
   ```dart
   import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';
   ```

2. **適切なファクトリコンストラクタを使用**:
   ```dart
   UnifiedNetworkException.timeout('タイムアウト');
   UnifiedSecurityException.apiKeyNotFound('API_KEY');
   ```

3. **UnifiedExceptionHandlerを活用**:
   ```dart
   final handler = UnifiedExceptionHandler();
   final result = await handler.executeAsync(riskyOperation);
   ```

4. **適切な重要度を設定**:
   ```dart
   // 重要度は自動で設定されるが、カスタム例外では明示的に設定
   BaseException('Error', severity: ExceptionSeverity.high);
   ```

### DON'T ❌

1. **古い例外クラスの新規使用**:
   ```dart
   // ❌ 非推奨
   throw NetworkException('Error');
   throw ApiException('Error');
   throw SecurityException('Error');
   ```

2. **例外の直接 toString() 使用**:
   ```dart
   // ❌ 技術的すぎる
   showDialog(content: exception.toString());
   
   // ✅ ユーザーフレンドリー
   showDialog(content: result.userMessage);
   ```

3. **ログレベル無視**:
   ```dart
   // ❌ 全て同じレベルでログ
   print(exception.toString());
   
   // ✅ 重要度に応じたログ
   handler.handle(exception); // 自動的に適切なレベルでログ出力
   ```

## 実際のコードでの使用例

### Repository層での使用

```dart
class StoreRepository {
  final HotpepperApiService _apiService;
  final UnifiedExceptionHandler _errorHandler = UnifiedExceptionHandler();
  
  StoreRepository(this._apiService);
  
  Future<List<Store>> getStores({String? location}) async {
    final result = await _errorHandler.executeAsync(() async {
      try {
        return await _apiService.fetchStores(location: location);
      } on SocketException catch (e, stackTrace) {
        throw UnifiedNetworkException.connection(
          'ネットワークに接続できません',
          cause: e,
          stackTrace: stackTrace,
        );
      } on TimeoutException catch (e, stackTrace) {
        throw UnifiedNetworkException.timeout(
          'リクエストがタイムアウトしました',
          cause: e,
          stackTrace: stackTrace,
        );
      } on HttpException catch (e, stackTrace) {
        if (e.message.contains('429')) {
          throw UnifiedNetworkException.rateLimitExceeded(
            'API利用制限に達しました',
            statusCode: 429,
            cause: e,
            stackTrace: stackTrace,
          );
        }
        throw UnifiedNetworkException.http(
          e.message,
          statusCode: e.uri != null ? 500 : 0,
          cause: e,
          stackTrace: stackTrace,
        );
      }
    });
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      // ログは既にUnifiedExceptionHandlerで出力済み
      throw result.exception!;
    }
  }
}
```

### Provider/Controller層での使用

```dart
class SearchProvider with ChangeNotifier {
  final StoreRepository _repository;
  final UnifiedExceptionHandler _errorHandler = UnifiedExceptionHandler();
  
  List<Store> _stores = [];
  String _userErrorMessage = '';
  bool _isLoading = false;
  
  String get userErrorMessage => _userErrorMessage;
  bool get isLoading => _isLoading;
  List<Store> get stores => _stores;
  
  Future<void> searchStores(String location) async {
    _isLoading = true;
    _userErrorMessage = '';
    notifyListeners();
    
    final result = await _errorHandler.executeAsync(() async {
      return await _repository.getStores(location: location);
    });
    
    _isLoading = false;
    
    if (result.isSuccess) {
      _stores = result.data!;
      _userErrorMessage = '';
    } else {
      _stores = [];
      _userErrorMessage = result.userMessage; // ユーザーフレンドリーなメッセージ
    }
    
    notifyListeners();
  }
}
```

### Widget層での使用

```dart
class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              // 検索フィールド
              SearchField(
                onSearch: (location) => provider.searchStores(location),
              ),
              
              // エラー表示
              if (provider.userErrorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.userErrorMessage, // 日本語の分かりやすいメッセージ
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // ローディング・結果表示
              Expanded(
                child: provider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : StoreList(stores: provider.stores),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### API Service層での使用

```dart
class HotpepperApiService {
  final http.Client _httpClient;
  
  HotpepperApiService(this._httpClient);
  
  Future<List<Store>> fetchStores({String? location}) async {
    final apiKey = await _getApiKey();
    final url = _buildApiUrl(location: location, apiKey: apiKey);
    
    try {
      final response = await _httpClient.get(url).timeout(
        Duration(seconds: 30),
      );
      
      if (response.statusCode == 200) {
        return _parseStoresResponse(response.body);
      } else if (response.statusCode == 401) {
        throw UnifiedNetworkException.unauthorized(
          'APIキーが無効です',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 429) {
        throw UnifiedNetworkException.rateLimitExceeded(
          'API利用制限に達しました',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 503) {
        throw UnifiedNetworkException.maintenance(
          'サービスがメンテナンス中です',
        );
      } else {
        throw UnifiedNetworkException.http(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e, stackTrace) {
      throw UnifiedNetworkException.connection(
        'ネットワーク接続を確認してください',
        cause: e,
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (e, stackTrace) {
      throw UnifiedNetworkException.timeout(
        'リクエストがタイムアウトしました',
        cause: e,
        stackTrace: stackTrace,
      );
    } on FormatException catch (e, stackTrace) {
      throw UnifiedNetworkException.api(
        'APIレスポンスの解析に失敗しました',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  Future<String> _getApiKey() async {
    try {
      return await ConfigManager.getApiKey('HOTPEPPER_API_KEY');
    } catch (e, stackTrace) {
      throw UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');
    }
  }
}
```

## テストでの使用例

```dart
test('should handle network error correctly', () {
  // Arrange
  final exception = UnifiedNetworkException.api('API Error', statusCode: 500);
  final handler = UnifiedExceptionHandler();

  // Act
  final result = handler.handle<String>(exception);

  // Assert
  expect(result.isFailure, isTrue);
  expect(result.userMessage, equals('ネットワークエラーが発生しました。しばらくしてからお試しください。'));
  expect(result.severity, equals(ExceptionSeverity.high));
});

test('should handle rate limit exceeded with specific message', () {
  // Arrange
  final exception = UnifiedNetworkException.rateLimitExceeded(
    'Rate limit exceeded',
    statusCode: 429,
  );
  final handler = UnifiedExceptionHandler();

  // Act
  final result = handler.handle<String>(exception);

  // Assert
  expect(result.isFailure, isTrue);
  expect(result.userMessage, equals('API利用制限に達しました。しばらくしてからお試しください。'));
  expect(result.severity, equals(ExceptionSeverity.high));
});
```

## ログ出力

統一エラーハンドラーは、重要度に応じて適切なレベルでログを出力します：

- `ExceptionSeverity.low` → INFO (500)
- `ExceptionSeverity.medium` → WARNING (900)  
- `ExceptionSeverity.high` → SEVERE (1000)
- `ExceptionSeverity.critical` → SHOUT (1200)

## 後方互換性

既存の例外クラスは当面維持されますが、`@Deprecated`アノテーションが付与されています。新しいコードでは統一例外システムを使用してください。

## 今後の拡張

1. **カスタムエラー種別の追加**
2. **Result型の活用拡大** 
3. **エラーレポート機能の統合**
4. **多言語対応エラーメッセージ**

---

このガイドラインに従って、一貫性のある保守しやすいエラーハンドリングを実装してください。