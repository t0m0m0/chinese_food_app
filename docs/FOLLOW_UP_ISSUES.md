# LocationService改善 フォローアップIssue一覧

## 概要
Issue #38「LocationService のコメントアウトされたコードとエラーハンドリングの改善」完了後の、継続改善項目です。

## Issue #42: 実GPS機能の実装 (HIGH Priority)

### 背景
現在はダミーデータを返しているGPS機能を、実際のGeolocatorパッケージを使用した実装に変更する。

### 実装内容
1. **Geolocatorパッケージ有効化**
   - `pubspec.yaml`でgeolocatorのコメントアウト解除
   - import文の有効化

2. **実際の権限チェック実装**
   ```dart
   Future<PermissionResult> checkLocationPermission() async {
     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     if (!serviceEnabled) {
       return PermissionResult.denied('位置情報サービスが無効です', 
         errorType: LocationServiceDisabledError('サービス無効'));
     }

     LocationPermission permission = await Geolocator.checkPermission();
     if (permission == LocationPermission.denied) {
       permission = await Geolocator.requestPermission();
       if (permission == LocationPermission.denied) {
         return PermissionResult.denied('位置情報の権限が拒否されました',
           errorType: LocationPermissionDeniedError('権限拒否'));
       }
     }

     if (permission == LocationPermission.deniedForever) {
       return PermissionResult.denied('位置情報の権限が永続的に拒否されています',
         errorType: LocationPermissionDeniedError('永続拒否'));
     }

     return PermissionResult.granted();
   }
   ```

3. **実GPS座標取得実装**
   ```dart
   final position = await Geolocator.getCurrentPosition(
     locationSettings: LocationSettings(
       accuracy: LocationAccuracy.high,
       distanceFilter: 100,
     ),
   );
   ```

### テスト戦略
- 実デバイステスト: Android/iOS実機
- 権限シナリオテスト: 許可/拒否/永続拒否
- エラーケーステスト: タイムアウト/サービス無効

### 受け入れ条件
- [ ] 実GPS座標が取得できる
- [ ] 権限チェックが正常に動作する
- [ ] エラーハンドリングが適切
- [ ] 既存テストがすべて通る
- [ ] 新規テストカバレッジ80%以上

---

## Issue #43: 包括的エラーシミュレーション機能 (MEDIUM Priority)

### 背景
テスト環境でより詳細なエラーパターンをシミュレーションできる機能を追加する。

### 実装内容
1. **拡張環境変数**
   - `GPS_ACCURACY_MODE`: 精度シミュレーション
   - `NETWORK_DELAY_MODE`: ネットワーク遅延
   - `BATTERY_OPTIMIZATION_MODE`: バッテリー最適化影響

2. **モック機能拡張**
   ```dart
   class LocationServiceMock extends LocationService {
     final Map<String, dynamic> config;
     LocationServiceMock(this.config);
     
     @override
     Future<LocationServiceResult> getCurrentPosition() async {
       if (config['simulateTimeout'] == true) {
         await Future.delayed(Duration(seconds: 10));
         throw TimeoutException('GPS timeout');
       }
       // ...
     }
   }
   ```

3. **CI/CD統合**
   - 各エラーパターンの自動テスト
   - パフォーマンステスト
   - デバイス別動作確認

### 受け入れ条件
- [ ] 10種類以上のエラーパターンをシミュレート可能
- [ ] CI/CDで全パターンテスト実行
- [ ] ドキュメント更新

---

## Issue #44: アーキテクチャリファクタリング (LOW Priority)

### 背景
コードの保守性と拡張性をさらに向上させるためのアーキテクチャ改善。

### 実装内容
1. **Dependency Injection導入**
   ```dart
   abstract class LocationConfig {
     String get locationMode;
     Map<String, String> get environment;
   }

   class LocationService {
     final LocationConfig config;
     final LocationStrategy strategy;
     
     LocationService({required this.config, required this.strategy});
   }
   ```

2. **Result型パターン採用**
   ```dart
   sealed class Result<T> {
     const Result();
   }
   
   class Success<T> extends Result<T> {
     final T data;
     const Success(this.data);
   }
   
   class Failure<T> extends Result<T> {
     final LocationError error;
     const Failure(this.error);
   }
   ```

3. **Strategy Pattern実装**
   ```dart
   abstract class LocationStrategy {
     Future<Result<Position>> getCurrentPosition();
   }

   class ProductionLocationStrategy implements LocationStrategy { ... }
   class TestLocationStrategy implements LocationStrategy { ... }
   class MockLocationStrategy implements LocationStrategy { ... }
   ```

### 受け入れ条件
- [ ] DIコンテナ導入（get_it or injectable）
- [ ] Result型への全面移行
- [ ] Strategy Pattern実装
- [ ] 既存機能の互換性維持
- [ ] パフォーマンス劣化なし

---

## Issue #45: パフォーマンス最適化 (MEDIUM Priority)

### 背景
位置情報取得の高速化とバッテリー消費削減。

### 実装内容
1. **位置情報キャッシュ機能**
   - 一定時間内の同一位置キャッシュ
   - 移動距離による更新判定

2. **バッテリー最適化**
   - 精度と消費電力のバランス調整
   - バックグラウンド位置取得制御

3. **非同期処理最適化**
   - Stream-based location updates
   - Isolateを使用した重い処理の分離

### 受け入れ条件
- [ ] 位置取得速度50%向上
- [ ] バッテリー消費20%削減
- [ ] キャッシュ機能テスト
- [ ] パフォーマンステスト自動化

---

## 実装優先度と時期

| Issue | 優先度 | 予定時期 | 工数見積 |
|-------|--------|----------|----------|
| #42 実GPS機能 | HIGH | Sprint 2.1 | 5日 |
| #43 エラーシミュレーション | MEDIUM | Sprint 2.2 | 3日 |
| #45 パフォーマンス最適化 | MEDIUM | Sprint 2.3 | 4日 |
| #44 アーキテクチャ改善 | LOW | Sprint 3.0 | 7日 |

## リスク管理

### Issue #42のリスク
- **権限問題**: iOS/Androidの権限ポリシー差異
- **対策**: プラットフォーム別テスト強化

### Issue #43のリスク  
- **テスト複雑化**: 多数のパターンによる保守困難
- **対策**: テストカテゴリ分類、自動化

### Issue #44のリスク
- **破壊的変更**: 既存コードへの影響
- **対策**: 段階的移行、互換レイヤー提供

---

*最終更新: 2024年6月28日*  
*作成者: Claude Code (claude.ai/code)*