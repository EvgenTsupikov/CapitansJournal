// lib/pages/templates_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/template.dart';
import '../l10n/app_localizations.dart';

class TemplatesPage extends StatefulWidget {
  final List<Template> templates;
  final void Function(List<Template>) onTemplatesChanged;

  const TemplatesPage({
    super.key,
    required this.templates,
    required this.onTemplatesChanged,
  });

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  late List<Template> _templates;

  @override
  void initState() {
    super.initState();
    _templates = List.from(widget.templates);
  }

  void _saveTemplates() {
    widget.onTemplatesChanged(_templates);
  }

  void _addTemplate() {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final stateController = TextEditingController();
    final practicesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Create Template' : 'Создать шаблон'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Name (Morning/Evening)' : 'Название (утро/вечер)',
                  hintText: isEnglish ? 'Morning' : 'Утро',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Location' : 'Локация',
                  hintText: isEnglish ? 'Home' : 'Дом',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'State' : 'Состояние',
                  hintText: isEnglish ? 'Good' : 'Хорошее',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: practicesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Practices' : 'Практики',
                  hintText: isEnglish ? 'Meditation, Exercise' : 'Медитация, Упражнения',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final template = Template(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  state: stateController.text.trim(),
                  practices: practicesController.text.trim(),
                );
                setState(() {
                  _templates.add(template);
                });
                _saveTemplates();
                Navigator.pop(context);
              }
            },
            child: Text(isEnglish ? 'Create' : 'Создать'),
          ),
        ],
      ),
    );
  }

  void _editTemplate(Template template) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final nameController = TextEditingController(text: template.name);
    final locationController = TextEditingController(text: template.location);
    final stateController = TextEditingController(text: template.state);
    final practicesController = TextEditingController(text: template.practices);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Edit Template' : 'Редактировать шаблон'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Name (Morning/Evening)' : 'Название (утро/вечер)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Location' : 'Локация',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'State' : 'Состояние',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: practicesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Practices' : 'Практики',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final index = _templates.indexWhere((t) => t.id == template.id);
                if (index != -1) {
                  setState(() {
                    _templates[index] = Template(
                      id: template.id,
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      state: stateController.text.trim(),
                      practices: practicesController.text.trim(),
                    );
                  });
                  _saveTemplates();
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEnglish ? 'Save' : 'Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(Template template) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Template?' : 'Удалить шаблон?'),
        content: Text(
          isEnglish
              ? 'Are you sure you want to delete this template?'
              : 'Вы уверены, что хотите удалить этот шаблон?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _templates.removeWhere((t) => t.id == template.id);
              });
              _saveTemplates();
              Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Templates' : 'Шаблоны'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTemplate,
            tooltip: isEnglish ? 'Add Template' : 'Добавить шаблон',
          ),
        ],
      ),
      body: _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEnglish ? 'No templates yet' : 'Шаблонов пока нет',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish
                        ? 'Tap + to create your first template'
                        : 'Нажмите + чтобы создать первый шаблон',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (template.location.isNotEmpty)
                          Text('${isEnglish ? "Location" : "Локация"}: ${template.location}'),
                        if (template.state.isNotEmpty)
                          Text('${isEnglish ? "State" : "Состояние"}: ${template.state}'),
                        if (template.practices.isNotEmpty)
                          Text('${isEnglish ? "Practices" : "Практики"}: ${template.practices}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTemplate(template),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTemplate(template),
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

