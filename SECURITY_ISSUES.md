# セキュリティ改善課題

このドキュメントは、セキュリティ監査の結果に基づく改善課題をまとめたものです。
以下の内容を個別のGitHub Issueとして作成することを推奨します。

---

## Issue 1: [Security][Critical] 暗号化実装の改善：XOR暗号からAES-GCMへの移行

### 概要
現在の設定値暗号化実装（`lib/core/config/config_encryption.dart`）は、単純なXOR暗号を使用しており、セキュリティ上の重大な脆弱性があります。

### 問題点

#### 1. 脆弱な暗号化アルゴリズム
- **単純なXOR暗号**: 容易に解読可能で、暗号学的に安全ではありません
- **認証なし**: データの完全性チェックがなく、改ざん検知ができません
- **デフォルトキーが固定**: `default_key_change_in_production` というハードコードされた値が使用されています

```dart
// 現在の実装（lib/core/config/config_encryption.dart:23-31）
for (int i = 0; i < plaintextBytes.length; i++) {
  encrypted.add(plaintextBytes[i] ^ keyBytes[i % keyBytes.length]);
}
```

#### 2. 不適切なエラーハンドリング
- 暗号化/復号化失敗時に平文をそのまま返す仕様は危険です

```dart
// lib/core/config/config_encryption.dart:29-30
catch (e) {
  return plaintext; // ❌ 平文を返すべきではない
}
```

### セキュリティリスク

- 🔴 **Critical**: APIキーや機密情報が簡単に復元される可能性
- 🔴 **Critical**: 中間者攻撃や傍受により、暗号化された設定値が解読される
- 🔴 **Critical**: デフォルトキーの使用により、本番環境でも保護されない可能性

### 推奨対策

#### 1. AES-GCMの使用
既に `pointycastle: ^3.9.1` がインストール済みなので、これを活用：

```dart
import 'package:pointycastle/export.dart';

class ConfigEncryption {
  // AES-GCM (Galois/Counter Mode) を使用
  static String encrypt(String plaintext) {
    final key = _generateSecureKey(); // 256-bit key
    final nonce = _generateNonce();   // 96-bit nonce

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, []));

    // 暗号化 + 認証タグ生成
    final encrypted = cipher.process(utf8.encode(plaintext));

    return base64Encode(nonce + encrypted);
  }
}
```

#### 2. Flutter Secure Storageの活用（代替案）
APIキーの保存には Flutter Secure Storage を使用する方が適切：

```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'api_key', value: apiKey);
```

### 実装タスク

- [ ] `ConfigEncryption` クラスを AES-GCM 実装に置き換え
- [ ] 暗号化キーの安全な生成・管理方法を実装
- [ ] エラーハンドリングを改善（失敗時は例外をスロー）
- [ ] 既存の暗号化データのマイグレーション計画を策定
- [ ] ユニットテストを作成（暗号化/復号化の正確性、改ざん検知など）

### 参考資料
- [OWASP Mobile Security - Cryptography](https://owasp.org/www-project-mobile-security/)
- [pointycastle パッケージ](https://pub.dev/packages/pointycastle)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)

### 優先度
🔴 **Critical** - 早急な対応が必要

### ラベル
`security`, `critical`, `enhancement`

### 関連ファイル
- `lib/core/config/config_encryption.dart`
- `lib/core/config/security_config.dart`

---

## Issue 2: [Security][Critical] SSL証明書バイパス機能の制限

### 概要
`lib/core/network/ssl_bypass_http_client.dart` の存在により、SSL/TLS検証をバイパスできる状態になっています。これは開発時の利便性のためと思われますが、本番環境で有効になると深刻なセキュリティリスクとなります。

### 問題点

#### 1. 中間者攻撃（MITM）のリスク
- SSL/TLS検証をバイパスすると、通信内容が傍受・改ざんされる可能性があります
- APIキーやユーザーデータが平文で漏洩する危険性があります

#### 2. 本番環境への混入リスク
- 開発用コードが誤って本番ビルドに含まれる可能性
- 条件分岐によるバイパス有効化の危険性

### セキュリティリスク

- 🔴 **Critical**: 中間者攻撃により全通信内容が漏洩する可能性
- 🔴 **Critical**: HotPepper APIへのリクエスト/レスポンスが傍受される
- 🔴 **Critical**: 不正なサーバーへの接続を許可してしまう

### 推奨対策

#### 1. 開発環境のみでの使用を保証

```dart
// lib/core/network/ssl_bypass_http_client.dart
class SSLBypassHttpClient {
  factory SSLBypassHttpClient() {
    // 本番環境では絶対に使用しない
    assert(() {
      if (kReleaseMode) {
        throw StateError('SSL bypass is not allowed in release builds');
      }
      return true;
    }());

    // さらにコンパイル時チェック
    if (const bool.fromEnvironment('dart.vm.product')) {
      throw StateError('SSL bypass is disabled in production');
    }

    return SSLBypassHttpClient._internal();
  }
}
```

#### 2. 証明書ピンニングの実装（推奨）
より安全な開発環境構築のため、自己署名証明書のピンニングを検討：

```dart
import 'dart:io';

class CertificatePinningClient {
  static SecurityContext getSecurityContext() {
    final context = SecurityContext.defaultContext;

    // 開発用証明書を明示的に信頼
    context.setTrustedCertificatesBytes(
      File('assets/certs/dev_cert.pem').readAsBytesSync()
    );

    return context;
  }
}
```

#### 3. ビルド時の除外設定

```yaml
# pubspec.yaml
flutter:
  assets:
    - lib/core/network/ssl_bypass_http_client.dart

# 本番ビルド時に除外
# build.gradle (Android)
buildTypes {
  release {
    // SSL bypass を除外するProGuardルール
  }
}
```

### 実装タスク

- [ ] SSL bypass を開発環境のみに制限するアサーションを追加
- [ ] 本番ビルドでのコンパイルエラーを設定
- [ ] 証明書ピンニングの実装を検討
- [ ] CI/CDパイプラインでSSL bypass使用を検出するチェックを追加
- [ ] コードレビューガイドラインに SSL bypass の使用禁止を明記

### 参考資料
- [OWASP Mobile Top 10 - M3: Insecure Communication](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://flutter.dev/security)

### 優先度
🔴 **Critical** - 早急な対応が必要

### ラベル
`security`, `critical`, `bug`

### 関連ファイル
- `lib/core/network/ssl_bypass_http_client.dart`
- `lib/data/datasources/hotpepper_proxy_datasource.dart` (使用箇所)

---

## Issue 3: [Security][Medium] 入力検証の強化

### 概要
APIパラメータやユーザー入力に対する検証が不十分です。特に位置情報関連のパラメータ（緯度・経度）や検索パラメータの範囲チェックが不足しています。

### 問題点

#### 1. 位置情報パラメータの検証不足
- 緯度・経度の有効範囲チェックがない
- 不正な値がAPIに送信される可能性

#### 2. 検索パラメータの検証不足
- `range`, `count`, `start` パラメータの範囲チェックが不十分
- SQLインジェクションのリスクは低いが、予期しない動作の原因となる

### セキュリティリスク

- 🟡 **Medium**: 不正なパラメータによるAPIエラーや予期しない動作
- 🟡 **Medium**: クライアント側バリデーション不足によるUX低下
- 🟡 **Medium**: サーバーサイドへの不正なリクエスト送信

### 推奨対策

#### 1. 入力検証ユーティリティの作成

```dart
// lib/core/utils/input_validator.dart
class InputValidator {
  /// 緯度の検証
  static void validateLatitude(double? lat) {
    if (lat == null) {
      throw ValidationException('Latitude is required');
    }
    if (lat < -90.0 || lat > 90.0) {
      throw ValidationException('Latitude must be between -90 and 90');
    }
  }

  /// 経度の検証
  static void validateLongitude(double? lng) {
    if (lng == null) {
      throw ValidationException('Longitude is required');
    }
    if (lng < -180.0 || lng > 180.0) {
      throw ValidationException('Longitude must be between -180 and 180');
    }
  }

  /// 検索範囲の検証
  static void validateRange(int range) {
    if (range < 1 || range > 5) {
      throw ValidationException('Range must be between 1 and 5');
    }
  }

  /// 取得件数の検証
  static void validateCount(int count) {
    if (count < 1 || count > 100) {
      throw ValidationException('Count must be between 1 and 100');
    }
  }
}
```

#### 2. データソースでの検証適用

```dart
// lib/data/datasources/hotpepper_proxy_datasource.dart
Future<HotpepperSearchResponse> searchStores({
  double? lat,
  double? lng,
  // ...
}) async {
  // 入力検証
  if (lat != null || lng != null) {
    InputValidator.validateLatitude(lat);
    InputValidator.validateLongitude(lng);
  }
  InputValidator.validateRange(range);
  InputValidator.validateCount(count);

  // API呼び出し
  // ...
}
```

#### 3. ユーザー入力のサニタイゼーション

```dart
// 検索キーワードのサニタイゼーション
class StringSanitizer {
  /// 特殊文字を除去
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[<>\'\"&]'), '')
        .trim();
  }

  /// 最大長制限
  static String truncate(String input, int maxLength) {
    if (input.length > maxLength) {
      return input.substring(0, maxLength);
    }
    return input;
  }
}
```

### 実装タスク

- [ ] `InputValidator` クラスを作成
- [ ] 全データソースに入力検証を追加
- [ ] ユーザー入力のサニタイゼーション処理を実装
- [ ] バリデーションエラーのユーザーフレンドリーなメッセージを作成
- [ ] ユニットテストを作成（境界値テスト含む）

### 参考資料
- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)

### 優先度
🟡 **Medium** - 重要だが緊急性は低い

### ラベル
`security`, `enhancement`, `validation`

### 関連ファイル
- `lib/data/datasources/hotpepper_proxy_datasource.dart`
- `lib/domain/usecases/location/`
- `lib/presentation/providers/store_provider.dart`

---

## Issue 4: [Security][Medium] ログ出力のセキュリティ改善

### 概要
デバッグログに機密情報（APIキーの一部など）が含まれており、本番環境でのログ漏洩リスクがあります。

### 問題点

#### 1. APIキー情報のログ出力
```dart
// lib/main.dart:101-102
CrashHandler.logEvent('SDK_INIT_START', details: {
  'api_key_first_6': apiKey.substring(0, 6),  // ❌ APIキーの一部を出力
});
```

#### 2. ログレベル管理の不明確さ
- 環境別のログレベル制御が不十分
- 本番環境でもデバッグログが出力される可能性

### セキュリティリスク

- 🟡 **Medium**: ログファイルからAPIキーが推測される可能性
- 🟡 **Medium**: クラッシュレポートに機密情報が含まれる
- 🟡 **Medium**: デバッグ情報の過剰な露出

### 推奨対策

#### 1. 環境別ログ設定の強化

```dart
// lib/core/utils/app_logger.dart
class AppLogger {
  static bool get _shouldLog {
    if (kReleaseMode) return false;
    return const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
  }

  static void debug(String message, {Map<String, dynamic>? details}) {
    if (!_shouldLog) return;
    developer.log(message, name: 'DEBUG', level: 500);
  }

  static void info(String message) {
    // 本番環境でも重要な情報のみ出力
    developer.log(message, name: 'INFO', level: 800);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    // エラーは全環境で出力（ただし機密情報を除外）
    final sanitized = _sanitizeMessage(message);
    developer.log(sanitized, name: 'ERROR', level: 1000);
  }

  /// 機密情報をマスキング
  static String _sanitizeMessage(String message) {
    return message
        .replaceAll(RegExp(r'api[_-]?key[:=]\s*\S+', caseSensitive: false), 'api_key=***')
        .replaceAll(RegExp(r'token[:=]\s*\S+', caseSensitive: false), 'token=***')
        .replaceAll(RegExp(r'password[:=]\s*\S+', caseSensitive: false), 'password=***');
  }
}
```

#### 2. APIキー情報の完全除外

```dart
// main.dartの修正
CrashHandler.logEvent('SDK_INIT_START', details: {
  // 'api_key_first_6': apiKey.substring(0, 6),  // ❌ 削除
  'timestamp': DateTime.now().toIso8601String(),
  'platform': Platform.operatingSystem,
});
```

#### 3. クラッシュレポートのフィルタリング

```dart
// lib/core/debug/crash_handler.dart
class CrashHandler {
  static void logEvent(String event, {Map<String, dynamic>? details}) {
    if (kReleaseMode) {
      // 本番環境では機密情報を除外
      final sanitized = _sanitizeDetails(details);
      _sendToAnalytics(event, sanitized);
    } else {
      // 開発環境ではそのまま出力
      developer.log(event, name: 'CrashHandler');
    }
  }

  static Map<String, dynamic>? _sanitizeDetails(Map<String, dynamic>? details) {
    if (details == null) return null;

    final sanitized = Map<String, dynamic>.from(details);
    final sensitiveKeys = ['api_key', 'token', 'password', 'secret'];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***';
      }
    }

    return sanitized;
  }
}
```

### 実装タスク

- [ ] 環境別ログレベル制御を実装
- [ ] APIキー情報のログ出力を削除
- [ ] 機密情報の自動マスキング機能を実装
- [ ] クラッシュレポートのフィルタリング機能を追加
- [ ] ログ設定のドキュメントを作成

### 参考資料
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [Flutter Logging Best Practices](https://flutter.dev/docs/testing/errors)

### 優先度
🟡 **Medium** - 重要だが緊急性は低い

### ラベル
`security`, `enhancement`, `logging`

### 関連ファイル
- `lib/core/utils/app_logger.dart`
- `lib/core/debug/crash_handler.dart`
- `lib/main.dart`

---

## 追加推奨事項（Future Enhancements）

### Issue 5: [Security][Low] データベース暗号化の検討

将来的にユーザー個人情報を扱う場合に備えて、SQLiteデータベースの暗号化を検討：

- SQLCipher for Flutter の導入
- ユーザーデータの暗号化保存
- バックアップデータの保護

### Issue 6: [Security][Low] 認証・認可システムの設計

現在は認証機能がありませんが、将来的な実装に備えて：

- OAuth 2.0 / OpenID Connect の検討
- JWT トークン管理
- セッション管理とタイムアウト

---

## 実装優先順位

1. 🔴 **Critical - 即座に対応**
   - Issue 1: 暗号化実装の改善
   - Issue 2: SSL証明書バイパスの制限

2. 🟡 **Medium - 1-2週間以内に対応**
   - Issue 3: 入力検証の強化
   - Issue 4: ログ出力のセキュリティ改善

3. 🟢 **Low - 将来的に検討**
   - Issue 5: データベース暗号化
   - Issue 6: 認証・認可システム

---

## まとめ

このアプリケーションは基本的なセキュリティ設計（プロキシサーバー、Drift ORM、権限管理）は良好ですが、暗号化とSSL/TLS周りの実装に重大な脆弱性があります。Critical な Issue を優先的に対応することで、セキュリティレベルを大幅に向上させることができます。
