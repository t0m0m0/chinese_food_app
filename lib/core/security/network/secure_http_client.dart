import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../../exceptions/infrastructure/security_exception.dart';

/// セキュアHTTPクライアント
///
/// SSL証明書ピニング、HTTPS強制、レスポンス検証機能を提供します。
class SecureHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Set<String> _pinnedCertificates;
  final bool _enforceHttps;
  final bool _validateCertificates;
  final Duration _timeout;
  final Map<String, String> _trustedHosts;

  /// セキュアHTTPクライアントを作成
  ///
  /// [client] - 内部HTTPクライアント
  /// [pinnedCertificates] - ピニングする証明書のSHA256ハッシュセット
  /// [enforceHttps] - HTTPS通信を強制するかどうか
  /// [validateCertificates] - 証明書の検証を行うかどうか
  /// [timeout] - リクエストタイムアウト
  /// [trustedHosts] - 信頼するホストとその証明書ハッシュのマップ
  SecureHttpClient({
    http.Client? client,
    Set<String>? pinnedCertificates,
    bool enforceHttps = true,
    bool validateCertificates = true,
    Duration? timeout,
    Map<String, String>? trustedHosts,
  })  : _inner = client ?? http.Client(),
        _pinnedCertificates = pinnedCertificates ?? {},
        _enforceHttps = enforceHttps,
        _validateCertificates = validateCertificates,
        _timeout = timeout ?? const Duration(seconds: 30),
        _trustedHosts = trustedHosts ?? {} {
    // デフォルトの信頼するホストを設定
    _setupDefaultTrustedHosts();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // セキュリティ検証
    _validateRequest(request);

    try {
      // セキュリティヘッダーを追加
      _addSecurityHeaders(request);

      // タイムアウト付きでリクエスト送信
      final response = await _inner.send(request).timeout(_timeout);

      // レスポンスのセキュリティ検証
      await _validateResponse(response, request.url.host);

      developer.log(
        'Secure HTTP ${request.method} ${request.url} - ${response.statusCode}',
        name: 'SecureHTTP',
      );

      return response;
    } catch (e) {
      developer.log(
        'Secure HTTP request failed: $e',
        name: 'SecureHTTP',
        level: 1000,
      );

      if (e is SecurityException) {
        rethrow;
      }

      throw SecurityException(
        'セキュアHTTP通信に失敗しました',
        context: '${request.method} ${request.url}',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// リクエストのセキュリティ検証
  void _validateRequest(http.BaseRequest request) {
    final uri = request.url;

    // HTTPS強制チェック
    if (_enforceHttps && uri.scheme != 'https') {
      throw SecurityException(
        'HTTPS通信が必要です',
        context: 'URL: ${uri.toString()}',
      );
    }

    // ホスト名の検証
    if (uri.host.isEmpty) {
      throw SecurityException(
        '無効なホスト名です',
        context: 'URL: ${uri.toString()}',
      );
    }

    // プライベートIPアドレスへのアクセス制限
    if (_isPrivateIpAddress(uri.host)) {
      throw SecurityException(
        'プライベートIPアドレスへのアクセスは制限されています',
        context: 'Host: ${uri.host}',
      );
    }
  }

  /// セキュリティヘッダーの追加
  void _addSecurityHeaders(http.BaseRequest request) {
    final headers = <String, String>{
      'User-Agent': 'MachiApp/1.0.0 (Security-Enhanced)',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    // CSRFトークンが必要な場合は追加
    if (request.method != 'GET' && request.method != 'HEAD') {
      headers['X-Requested-With'] = 'XMLHttpRequest';
    }

    request.headers.addAll(headers);
  }

  /// レスポンスのセキュリティ検証
  Future<void> _validateResponse(
      http.StreamedResponse response, String host) async {
    // ステータスコードの基本的な検証
    if (response.statusCode < 100 || response.statusCode >= 600) {
      throw SecurityException(
        '無効なHTTPステータスコードです',
        context: 'Status: ${response.statusCode}',
      );
    }

    // セキュリティヘッダーの検証
    _validateSecurityHeaders(response.headers);

    // SSL証明書ピニング検証（HTTPS接続の場合）
    if (response.request?.url.scheme == 'https') {
      await _validateSslCertificate(host);
    }
  }

  /// セキュリティヘッダーの検証
  void _validateSecurityHeaders(Map<String, String> headers) {
    // Content-Typeの検証
    final contentType = headers['content-type'] ?? '';
    if (contentType.isNotEmpty && !_isValidContentType(contentType)) {
      developer.log(
        'Potentially unsafe content-type: $contentType',
        name: 'SecureHTTP',
        level: 900, // WARNING
      );
    }

    // セキュリティヘッダーの存在確認（推奨事項）
    final recommendedHeaders = [
      'strict-transport-security',
      'x-content-type-options',
      'x-frame-options',
      'x-xss-protection',
    ];

    for (final header in recommendedHeaders) {
      if (!headers.containsKey(header)) {
        developer.log(
          'Missing recommended security header: $header',
          name: 'SecureHTTP',
          level: 800, // INFO
        );
      }
    }
  }

  /// SSL証明書ピニング検証
  Future<void> _validateSslCertificate(String host) async {
    if (!_validateCertificates) return;

    // 信頼するホストの証明書ハッシュをチェック
    final expectedHash = _trustedHosts[host];
    if (expectedHash != null) {
      // 実際の実装では、SSL証明書のハッシュを取得して比較します
      // ここではプレースホルダー実装
      final actualHash = await _getCertificateHash(host);

      if (actualHash != expectedHash) {
        throw SecurityException(
          'SSL証明書ピニング検証に失敗しました',
          context: 'Host: $host, Expected: $expectedHash, Actual: $actualHash',
        );
      }

      developer.log(
        'SSL certificate pinning validated for $host',
        name: 'SecureHTTP',
      );
    }

    // 共通の証明書ピニング検証
    if (_pinnedCertificates.isNotEmpty) {
      final actualHash = await _getCertificateHash(host);

      if (!_pinnedCertificates.contains(actualHash)) {
        throw SecurityException(
          'SSL証明書が信頼できる証明書リストに含まれていません',
          context: 'Host: $host, Certificate: $actualHash',
        );
      }
    }
  }

  /// SSL証明書のハッシュを取得
  ///
  /// 実際のSSL証明書を取得してSHA256ハッシュを計算
  Future<String> _getCertificateHash(String host) async {
    try {
      // HttpClientを使用してSSL証明書を取得
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      // 証明書の検証を無効化（証明書を取得するため）
      client.badCertificateCallback = (cert, host, port) {
        // 証明書のハッシュを計算するために一時的に許可
        return true;
      };

      HttpClientRequest? request;
      HttpClientResponse? response;

      try {
        // HTTPSリクエストを送信
        final uri = Uri.parse('https://$host/');
        request = await client.getUrl(uri);
        response = await request.close();

        // 証明書を取得
        final certificate = response.certificate;
        if (certificate == null) {
          throw SecurityException('SSL証明書を取得できませんでした');
        }

        // 証明書のDERエンコードされたデータを取得
        final certBytes = certificate.der;

        // SHA256ハッシュを計算
        final digest = sha256.convert(certBytes);

        developer.log(
          'SSL certificate hash calculated for $host: ${digest.toString()}',
          name: 'SecureHTTP',
        );

        return digest.toString();
      } finally {
        // レスポンスを閉じる
        try {
          await response?.drain();
        } catch (e) {
          // エラーを無視（クリーンアップ目的）
        }

        // クライアントを閉じる
        client.close();
      }
    } catch (e) {
      developer.log(
        'Failed to get SSL certificate hash for $host: $e',
        name: 'SecureHTTP',
        level: 1000,
      );

      throw SecurityException(
        'SSL証明書ハッシュの取得に失敗しました',
        context: 'Host: $host',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// プライベートIPアドレスかどうかを判定
  bool _isPrivateIpAddress(String host) {
    // IPv4プライベートアドレスの正規表現
    final privateIpv4Patterns = [
      RegExp(r'^10\.'), // 10.0.0.0/8
      RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.'), // 172.16.0.0/12
      RegExp(r'^192\.168\.'), // 192.168.0.0/16
      RegExp(r'^127\.'), // 127.0.0.0/8 (localhost)
    ];

    for (final pattern in privateIpv4Patterns) {
      if (pattern.hasMatch(host)) {
        return true;
      }
    }

    // localhostの判定
    if (host == 'localhost' || host == '::1') {
      return true;
    }

    return false;
  }

  /// 有効なContent-Typeかどうかを判定
  bool _isValidContentType(String contentType) {
    final validTypes = [
      'application/json',
      'application/xml',
      'text/html',
      'text/plain',
      'text/xml',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ];

    return validTypes.any((type) => contentType.toLowerCase().startsWith(type));
  }

  /// デフォルトの信頼するホストを設定
  void _setupDefaultTrustedHosts() {
    // 注意: 実際の証明書ハッシュは動的に取得されるため、
    // ここでは事前に設定しない。
    // 実際の運用では、証明書ローテーションに対応するため、
    // 複数のハッシュ値を設定するか、動的検証を行う。

    developer.log(
      'Default trusted hosts setup completed (dynamic validation enabled)',
      name: 'SecureHTTP',
    );
  }

  /// 信頼するホストを追加
  void addTrustedHost(String host, String certificateHash) {
    _trustedHosts[host] = certificateHash;
    developer.log(
      'Added trusted host: $host',
      name: 'SecureHTTP',
    );
  }

  /// 証明書ピニングを追加
  void addPinnedCertificate(String certificateHash) {
    _pinnedCertificates.add(certificateHash);
    developer.log(
      'Added pinned certificate: $certificateHash',
      name: 'SecureHTTP',
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// セキュアHTTPクライアント用のファクトリークラス
class SecureHttpClientFactory {
  /// 本番環境用のセキュアHTTPクライアントを作成
  static SecureHttpClient createForProduction() {
    return SecureHttpClient(
      enforceHttps: true,
      validateCertificates: true,
      timeout: const Duration(seconds: 30),
    );
  }

  /// 開発環境用のセキュアHTTPクライアントを作成
  static SecureHttpClient createForDevelopment() {
    return SecureHttpClient(
      enforceHttps: false, // 開発環境ではHTTPも許可
      validateCertificates: false, // 開発環境では証明書検証を緩和
      timeout: const Duration(seconds: 60),
    );
  }

  /// テスト環境用のセキュアHTTPクライアントを作成
  static SecureHttpClient createForTesting({
    http.Client? mockClient,
  }) {
    return SecureHttpClient(
      client: mockClient,
      enforceHttps: false,
      validateCertificates: false,
      timeout: const Duration(seconds: 10),
    );
  }
}
