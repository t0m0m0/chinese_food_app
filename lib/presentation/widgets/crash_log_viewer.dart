import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/debug/crash_handler.dart';

/// クラッシュログを表示・管理するデバッグ用ウィジェット
class CrashLogViewer extends StatefulWidget {
  const CrashLogViewer({super.key});

  @override
  State<CrashLogViewer> createState() => _CrashLogViewerState();
}

class _CrashLogViewerState extends State<CrashLogViewer> {
  List<String> _crashLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCrashLogs();
  }

  void _loadCrashLogs() {
    setState(() {
      _isLoading = true;
    });

    try {
      _crashLogs = CrashHandler.getCrashLogs();
    } catch (e) {
      _crashLogs = ['ログ読み込みエラー: $e'];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Center(
        child: Text('デバッグモードでのみ利用可能です'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps クラッシュログ'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCrashLogs,
            tooltip: '再読み込み',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'ログクリア',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'クリップボードにコピー',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportLogs,
        icon: const Icon(Icons.save_alt),
        label: const Text('ログ出力'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_crashLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('クラッシュログがありません'),
            Text('Google Maps関連の問題が発生していません',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ログ統計情報
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 ログ統計',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('総ログ数: ${_crashLogs.length}'),
              Text('Google Maps関連: ${_getGoogleMapsLogCount()}'),
              Text('最新ログ時刻: ${_getLatestLogTime()}'),
            ],
          ),
        ),
        // ログリスト
        Expanded(
          child: ListView.builder(
            itemCount: _crashLogs.length,
            itemBuilder: (context, index) {
              final log = _crashLogs[_crashLogs.length - 1 - index]; // 最新から表示
              final isGoogleMapsLog = log.contains('GOOGLE MAPS');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isGoogleMapsLog ? Colors.orange.shade50 : null,
                child: ExpansionTile(
                  leading: Icon(
                    isGoogleMapsLog ? Icons.map : Icons.bug_report,
                    color: isGoogleMapsLog ? Colors.orange : Colors.red,
                  ),
                  title: Text(
                    _getLogTitle(log),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _getLogTimestamp(log),
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        log,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getLogTitle(String log) {
    if (log.contains('GOOGLE MAPS EVENT')) {
      final lines = log.split('\n');
      final eventLine = lines.firstWhere(
        (line) => line.startsWith('Event:'),
        orElse: () => 'Google Maps Event',
      );
      return eventLine.replaceFirst('Event: ', '🗺️ ');
    }

    if (log.contains('CRASH DETECTED')) {
      return '💥 アプリクラッシュ';
    }

    return '📋 システムログ';
  }

  String _getLogTimestamp(String log) {
    final lines = log.split('\n');
    final timeLine = lines.firstWhere(
      (line) => line.startsWith('Time:'),
      orElse: () => 'Time: 不明',
    );
    return timeLine.replaceFirst('Time: ', '');
  }

  int _getGoogleMapsLogCount() {
    return _crashLogs.where((log) => log.contains('GOOGLE MAPS')).length;
  }

  String _getLatestLogTime() {
    if (_crashLogs.isEmpty) return '不明';

    final latestLog = _crashLogs.last;
    return _getLogTimestamp(latestLog);
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログクリア'),
        content: const Text('すべてのクラッシュログを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      CrashHandler.clearLogs();
      _loadCrashLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログをクリアしました')),
        );
      }
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final allLogs = _crashLogs.join('\n\n${'=' * 50}\n\n');
    await Clipboard.setData(ClipboardData(text: allLogs));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログをクリップボードにコピーしました')),
      );
    }
  }

  Future<void> _exportLogs() async {
    try {
      final logContent = await CrashHandler.exportLogsToFile();

      if (logContent != null && mounted) {
        // 簡易的な表示（実際のファイル出力は開発環境でのみ）
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ログ出力'),
            content: const SingleChildScrollView(
              child: Text('ログが出力されました。\nデバッグコンソールを確認してください。'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログを出力しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログ出力エラー: $e')),
        );
      }
    }
  }
}
