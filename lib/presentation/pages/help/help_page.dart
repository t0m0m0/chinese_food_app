import 'package:flutter/material.dart';
import '../../../core/services/support_service.dart';
import '../../widgets/help_section_widget.dart';
import '../../widgets/help_content_widget.dart';

/// ヘルプ・サポート画面
/// Issue #144: 運用・サポート体制整備のアプリ内ヘルプ機能
class HelpPage extends StatefulWidget {
  final SupportService supportService;

  const HelpPage({
    super.key,
    required this.supportService,
  });

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String? selectedSectionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: selectedSectionId == null
          ? _buildHelpSectionsList()
          : _buildHelpContent(),
    );
  }

  Widget _buildHelpSectionsList() {
    final sections = widget.supportService.getHelpSections();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return HelpSectionWidget(
          section: section,
          onTap: () {
            setState(() {
              selectedSectionId = section.id;
            });
          },
        );
      },
    );
  }

  Widget _buildHelpContent() {
    final content = widget.supportService.getHelpContent(selectedSectionId!);

    if (content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('コンテンツが見つかりません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedSectionId = null;
                });
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedSectionId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                content.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        // コンテンツ
        Expanded(
          child: HelpContentWidget(
            content: content,
            supportService: widget.supportService,
          ),
        ),
      ],
    );
  }
}
