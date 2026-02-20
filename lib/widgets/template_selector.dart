// lib/widgets/template_selector.dart
import 'package:flutter/material.dart';
import '../models/template.dart';
import '../l10n/app_localizations.dart';

class TemplateSelector extends StatelessWidget {
  final List<Template> templates;
  final void Function(String text) onTemplateSelected;
  final VoidCallback onManageTemplates;

  const TemplateSelector({
    super.key,
    required this.templates,
    required this.onTemplateSelected,
    required this.onManageTemplates,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    if (templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              isEnglish ? 'No templates' : 'Нет шаблонов',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onManageTemplates,
              child: Text(
                isEnglish ? 'Create' : 'Создать',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                isEnglish ? 'Templates' : 'Шаблоны',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                onPressed: onManageTemplates,
                tooltip: isEnglish ? 'Manage Templates' : 'Управление шаблонами',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((template) {
              return ActionChip(
                label: Text(template.name),
                onPressed: () => onTemplateSelected(template.generateText()),
                avatar: Icon(
                  template.name.toLowerCase().contains('утро') || 
                  template.name.toLowerCase().contains('morning')
                      ? Icons.wb_sunny
                      : Icons.nightlight_round,
                  size: 16,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

