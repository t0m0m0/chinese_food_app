import 'package:flutter/material.dart';
import '../../core/services/support_service.dart';

/// ヘルプセクションを表示するウィジェット
class HelpSectionWidget extends StatelessWidget {
  final HelpSection section;
  final VoidCallback onTap;

  const HelpSectionWidget({
    super.key,
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(
            _getIconData(section.icon),
            color: Colors.white,
          ),
        ),
        title: Text(
          section.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          section.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'help_outline':
        return Icons.help_outline;
      case 'school':
        return Icons.school;
      case 'build':
        return Icons.build;
      case 'info':
        return Icons.info;
      case 'mail':
        return Icons.mail;
      default:
        return Icons.help_outline;
    }
  }
}
