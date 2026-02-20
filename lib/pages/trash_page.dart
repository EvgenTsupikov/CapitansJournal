// lib/pages/trash_page.dart
import 'package:flutter/material.dart';
import '../models/deleted_note.dart';
import '../l10n/app_localizations.dart';

class TrashPage extends StatelessWidget {
  final List<DeletedNote> deletedNotes;
  final void Function(DeletedNote) onRestore;
  final void Function(DeletedNote) onPermanentDelete;

  const TrashPage({
    super.key,
    required this.deletedNotes,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDeletedDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Trash' : 'Корзина'),
        actions: [
          if (deletedNotes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(isEnglish ? 'Clear Trash?' : 'Очистить корзину?'),
                    content: Text(
                      isEnglish
                          ? 'All notes will be permanently deleted. This action cannot be undone.'
                          : 'Все заметки будут удалены навсегда. Это действие нельзя отменить.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n?.cancel ?? 'Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          for (final note in deletedNotes) {
                            onPermanentDelete(note);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEnglish
                                    ? 'Trash cleared'
                                    : 'Корзина очищена',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isEnglish ? 'Clear' : 'Очистить'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: isEnglish ? 'Clear all' : 'Очистить всё',
            ),
        ],
      ),
      body: deletedNotes.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'Trash is empty' : 'Корзина пуста',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: deletedNotes.length,
              itemBuilder: (context, index) {
                final deletedNote = deletedNotes[index];
                final daysLeft = deletedNote.daysUntilPermanentDelete;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(
                      deletedNote.note.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${isEnglish ? "Created" : "Создано"}: ${_formatDate(deletedNote.note.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${isEnglish ? "Deleted" : "Удалено"}: ${_formatDeletedDate(deletedNote.deletedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: daysLeft <= 7 ? Colors.red.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            daysLeft > 0
                                ? '${isEnglish ? "Will be deleted in" : "Будет удалено через"}: $daysLeft ${isEnglish ? "days" : daysLeft == 1 ? "день" : daysLeft < 5 ? "дня" : "дней"}'
                                : (isEnglish ? "Will be deleted soon" : "Будет удалено в ближайшее время"),
                            style: TextStyle(
                              fontSize: 11,
                              color: daysLeft <= 7 ? Colors.red.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () {
                            onRestore(deletedNote);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEnglish
                                      ? 'Note restored'
                                      : 'Заметка восстановлена',
                                ),
                              ),
                            );
                          },
                          tooltip: isEnglish ? 'Restore' : 'Восстановить',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  isEnglish
                                      ? 'Permanently Delete?'
                                      : 'Удалить навсегда?',
                                ),
                                content: Text(
                                  isEnglish
                                      ? 'This note will be permanently deleted and cannot be restored.'
                                      : 'Эта заметка будет удалена навсегда и не может быть восстановлена.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(l10n?.cancel ?? 'Отмена'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      onPermanentDelete(deletedNote);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEnglish
                                                ? 'Note permanently deleted'
                                                : 'Заметка удалена навсегда',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(isEnglish ? 'Delete' : 'Удалить'),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: isEnglish ? 'Delete forever' : 'Удалить навсегда',
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
}

