# LocationService 使用ガイド

## 概要

LocationServiceは町中華アプリにおける位置情報機能を提供するクラスです。  
TDDアプローチで開発され、環境変数による制御とエラーシミュレーション機能を備えています。

## 主な機能

### 1. 位置情報取得
- **GPS座標取得**: `getCurrentPosition()`
- **住所→座標変換**: `getCoordinatesFromAddress(String address)`  
- **座標→住所変換**: `getAddressFromCoordinates(double lat, double lng)`

### 2. 権限チェック
- **権限確認**: `checkLocationPermission()`
- **環境変数制御**: テスト用権限シミュレーション

### 3. エラーハンドリング
- **具体的エラー型**: 型安全なエラー処理
- **環境別制御**: 本番/テスト環境での動作分離

## 環境変数による制御

### LOCATION_MODE
位置情報取得の動作モードを制御します。

| 値 | 動作 | 用途 |
|---|---|---|
| `test` (デフォルト) | ダミーデータ返却 | 開発・テスト環境 |
| `production` | 権限チェック後GPS取得 | 本番環境 |

```bash
# テスト環境（デフォルト）
flutter test

# 本番環境シミュレーション
LOCATION_MODE=production flutter test
```

### PERMISSION_TEST_MODE  
権限チェックの結果をシミュレーションします。

| 値 | 結果 | エラー型 |
|---|---|---|
| 未設定 | 権限許可 | - |
| `denied` | 権限拒否 | `LocationPermissionDeniedError` |
| `denied_forever` | 永続拒否 | `LocationPermissionDeniedError` |
| `service_disabled` | サービス無効 | `LocationServiceDisabledError` |

```bash
# 権限拒否テスト
PERMISSION_TEST_MODE=denied flutter test

# サービス無効テスト  
PERMISSION_TEST_MODE=service_disabled flutter test
```

### LOCATION_ERROR_MODE
位置情報取得エラーをシミュレーションします。

| 値 | 結果 |
|---|---|
| 未設定 | 正常動作 |
| `permission_denied` | 権限拒否エラー |
| `service_disabled` | サービス無効エラー |
| `timeout` | タイムアウトエラー |

```bash
# タイムアウトエラーテスト
LOCATION_ERROR_MODE=timeout flutter test
```

## エラー型一覧

### 基底クラス
```dart
abstract class LocationError extends Error {
  final String message;
  LocationError(this.message);
}
```

### 具体的エラー型
- **LocationPermissionDeniedError**: 位置情報権限拒否
- **LocationServiceDisabledError**: 位置情報サービス無効
- **LocationTimeoutError**: GPS取得タイムアウト
- **LocationGeocodeError**: ジオコーディング失敗
- **LocationNetworkError**: ネットワーク接続エラー

## 使用例

### 基本的な位置情報取得
```dart
final locationService = LocationService();

// 現在位置取得
final result = await locationService.getCurrentPosition();
if (result.isSuccess) {
  print('緯度: ${result.lat}, 経度: ${result.lng}');
} else {
  print('エラー: ${result.error}');
}
```

### 権限チェック
```dart
final permission = await locationService.checkLocationPermission();
if (permission.isGranted) {
  // 位置情報取得処理
} else {
  print('権限エラー: ${permission.errorMessage}');
  // エラー型による分岐処理
  if (permission.errorType is LocationPermissionDeniedError) {
    // 権限要求UI表示
  }
}
```

### ジオコーディング
```dart
// 住所から座標を取得
final geocodeResult = await locationService.getCoordinatesFromAddress('東京都千代田区');
if (geocodeResult.isSuccess) {
  print('座標: ${geocodeResult.lat}, ${geocodeResult.lng}');
}

// 座標から住所を取得
final reverseResult = await locationService.getAddressFromCoordinates(35.6762, 139.6503);
if (reverseResult.isSuccess) {
  print('住所: ${reverseResult.address}');
}
```

## CI/CD での使用

### GitHub Actions例
```yaml
name: Location Service Tests
on: [push, pull_request]

jobs:
  test-permissions:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        permission_mode: [denied, denied_forever, service_disabled]
    steps:
      - uses: actions/checkout@v2
      - name: Test Permission ${{ matrix.permission_mode }}
        run: PERMISSION_TEST_MODE=${{ matrix.permission_mode }} flutter test
        
  test-errors:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        error_mode: [permission_denied, service_disabled, timeout]
    steps:
      - uses: actions/checkout@v2
      - name: Test Error ${{ matrix.error_mode }}
        run: LOCATION_ERROR_MODE=${{ matrix.error_mode }} flutter test

  test-production:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test Production Mode
        run: LOCATION_MODE=production flutter test
```

## 開発ロードマップ

### 現在の状況
- ✅ 環境変数による制御機能
- ✅ 具体的エラー型の実装
- ✅ 包括的テストカバレッジ
- ✅ 権限チェック機能（モック）

### 今後の予定

#### Sprint 2.1 (HIGH Priority)
- [ ] **Issue #42**: 実GPS機能実装
  - Geolocatorパッケージ有効化
  - 実際の権限チェック連携
  - LocationSettings設定

#### Sprint 2.2 (MEDIUM Priority)  
- [ ] **Issue #43**: テスト環境改善
  - より詳細なエラーシミュレーション
  - パフォーマンステスト機能

#### Sprint 3.0 (LOW Priority)
- [ ] **Issue #44**: アーキテクチャリファクタリング
  - Dependency Injection導入
  - Result型パターン採用
  - Strategy Pattern実装

## トラブルシューティング

### よくある問題

#### 1. テストが環境変数を認識しない
```bash
# 正しい設定方法
LOCATION_MODE=production flutter test

# 間違った設定方法  
flutter test --dart-define=LOCATION_MODE=production
```

#### 2. 権限エラーが発生しない
```bash
# 環境変数が正しく設定されているか確認
echo $PERMISSION_TEST_MODE

# テスト実行時に変数を設定
PERMISSION_TEST_MODE=denied flutter test test/services/location_permission_test.dart
```

#### 3. ジオコーディングエラー
- ネットワーク接続を確認
- API制限に達していないか確認
- 住所フォーマットが正しいか確認

### デバッグ方法
```dart
// LocationServiceのデバッグ出力を有効化
import 'dart:developer' as developer;

// メソッド内でログ出力
developer.log('LocationMode: ${Platform.environment["LOCATION_MODE"]}', name: 'LocationService');
```

## 関連ドキュメント
- [プロジェクト全体ガイド](./CLAUDE.md)
- [API仕様書](./docs/api-specification.md)
- [テスト戦略](./docs/testing-strategy.md)

---
*最終更新: 2024年6月28日*  
*生成者: Claude Code (claude.ai/code)*