import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SSL証明書検証をバイパスするHTTPクライアント（開発環境用）
///
/// 注意：本番環境では使用しないでください
/// Cloudflare Workersとの接続問題を一時的に解決するためのクライアント
class SSLBypassHttpClient extends http.BaseClient {
  final http.Client _inner;

  SSLBypassHttpClient._(this._inner);

  /// SSL証明書検証をバイパスするクライアントを作成
  factory SSLBypassHttpClient.create() {
    print('🚨 SSLBypassHttpClient.create() が呼び出されました');
    final httpClient = HttpClient();
    
    // SSL証明書検証をバイパス（開発環境のみ）
    httpClient.badCertificateCallback = (cert, host, port) {
      print('🔐 SSL証明書チェック: host=$host, port=$port');
      // Cloudflare WorkersのSSL問題を回避
      if (host.contains('workers.dev') || host.contains('cloudflare')) {
        print('⚠️ SSL証明書検証をバイパス: $host');
        return true; // 証明書を受け入れる
      }
      print('✅ SSL証明書検証実行: $host');
      return false; // その他のホストは正常な検証を行う
    };

    // 追加のSSL設定（iOS向け）
    try {
      httpClient.connectionTimeout = Duration(seconds: 30);
      httpClient.idleTimeout = Duration(seconds: 30);
    } catch (e) {
      print('⚠️ SSL追加設定エラー: $e');
    }

    print('🔧 SSLBypassHttpClient作成完了');
    return SSLBypassHttpClient._(IOClient(httpClient));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}