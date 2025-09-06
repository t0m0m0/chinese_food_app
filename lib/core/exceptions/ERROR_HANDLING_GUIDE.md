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