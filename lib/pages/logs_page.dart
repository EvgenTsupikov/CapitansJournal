// lib/pages/logs_page.dart
import 'package:flutter/material.dart';
import '../models/action_log.dart';
import '../l10n/app_localizations.dart';

class LogsPage extends StatelessWidget {
  final List<ActionLog> actionLogs;

  const LogsPage({
    super.key,
    required this.actionLogs,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Action Logs' : 'Логи действий'),
      ),
      body: actionLogs.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'No logs yet' : 'Логов пока нет',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: actionLogs.length,
              itemBuilder: (context, index) {
                final log = actionLogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      _getActionIcon(log.action),
                      color: _getActionColor(log.action),
                    ),
                    title: Text(
                      isEnglish ? log.actionNameEn : log.actionName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          log.noteText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(log.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'restore':
        return Icons.restore;
      case 'change_date':
        return Icons.calendar_today;
      case 'change_time':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'edit':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'restore':
        return Colors.orange;
      case 'change_date':
      case 'change_time':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

