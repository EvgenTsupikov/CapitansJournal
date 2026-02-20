// lib/pages/commands_page.dart
//
// Страница для настройки команд (#location, #state и т.д.)

import 'package:flutter/material.dart';
import '../models/command.dart';

class CommandsPage extends StatefulWidget {
  final List<Command> commands;
  final Function(List<Command>) onCommandsChanged;

  const CommandsPage({
    super.key,
    required this.commands,
    required this.onCommandsChanged,
  });

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  late List<Command> _commands;

  @override
  void initState() {
    super.initState();
    _commands = List.from(widget.commands);
  }

  void _saveCommands() {
    widget.onCommandsChanged(_commands);
  }

  void _addCommand() {
    showDialog(
      context: context,
      builder: (context) => _AddCommandDialog(
        onAdd: (name, values) {
          setState(() {
            _commands.add(Command(name: name, values: values));
            _saveCommands();
          });
        },
      ),
    );
  }

  void _editCommand(int index) {
    final command = _commands[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditCommandPage(
          command: command,
          onSave: (name, values) {
            setState(() {
              _commands[index] = Command(name: name, values: values);
              _saveCommands();
            });
          },
        ),
      ),
    );
  }

  void _deleteCommand(int index) {
    setState(() {
      _commands.removeAt(index);
      _saveCommands();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Commands' : 'Команды'),
      ),
      body: _commands.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'No commands yet' : 'Команды пока не добавлены',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              itemCount: _commands.length,
              itemBuilder: (context, index) {
                final command = _commands[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('#${command.name}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isEnglish ? 'Values:' : 'Значения:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: command.getAllPaths().map((path) {
                            return Chip(
                              label: Text(path),
                              labelStyle: const TextStyle(fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCommand(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCommand(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCommand,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddCommandDialog extends StatefulWidget {
  final Function(String name, List<LocationValue> values) onAdd;

  const _AddCommandDialog({required this.onAdd});

  @override
  State<_AddCommandDialog> createState() => _AddCommandDialogState();
}

class _AddCommandDialogState extends State<_AddCommandDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    // Создаем команду с пустым списком значений (пользователь добавит их позже)
    widget.onAdd(name, []);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return AlertDialog(
      title: Text(isEnglish ? 'Add Command' : 'Добавить команду'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isEnglish ? 'Command name (without #)' : 'Имя команды (без #)',
              hintText: 'location',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isEnglish ? 'Cancel' : 'Отмена'),
        ),
        TextButton(
          onPressed: _save,
          child: Text(isEnglish ? 'Add' : 'Добавить'),
        ),
      ],
    );
  }
}

/// Страница редактирования команды с иерархической структурой
class _EditCommandPage extends StatefulWidget {
  final Command command;
  final Function(String name, List<LocationValue> values) onSave;

  const _EditCommandPage({
    required this.command,
    required this.onSave,
  });

  @override
  State<_EditCommandPage> createState() => _EditCommandPageState();
}

class _EditCommandPageState extends State<_EditCommandPage> {
  late final TextEditingController _nameController;
  late List<LocationValue> _values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.command.name);
    _values = widget.command.values.map((v) => LocationValue(
      name: v.name,
      children: v.children.map((c) => LocationValue(
        name: c.name,
        children: c.children,
      )).toList(),
    )).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    widget.onSave(name, _values);
    Navigator.pop(context);
  }

  void _addCountry() {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(
        title: 'Add Country',
        onAdd: (name) {
          setState(() {
            _values.add(LocationValue(name: name));
          });
        },
      ),
    );
  }

  void _addCity(int countryIndex) {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(
        title: 'Add City',
        onAdd: (name) {
          setState(() {
            _values[countryIndex].children.add(LocationValue(name: name));
          });
        },
      ),
    );
  }

  void _addLocation(int countryIndex, int cityIndex) {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(
        title: 'Add Location',
        onAdd: (name) {
          setState(() {
            _values[countryIndex].children[cityIndex].children.add(LocationValue(name: name));
          });
        },
      ),
    );
  }

  void _deleteCountry(int index) {
    setState(() {
      _values.removeAt(index);
    });
  }

  void _deleteCity(int countryIndex, int cityIndex) {
    setState(() {
      _values[countryIndex].children.removeAt(cityIndex);
    });
  }

  void _deleteLocation(int countryIndex, int cityIndex, int locationIndex) {
    setState(() {
      _values[countryIndex].children[cityIndex].children.removeAt(locationIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Edit Command' : 'Редактировать команду'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isEnglish ? 'Command name (without #)' : 'Имя команды (без #)',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _values.length,
              itemBuilder: (context, countryIndex) {
                final country = _values[countryIndex];
                return ExpansionTile(
                  title: Text(country.name),
                  leading: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCountry(countryIndex),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addCity(countryIndex),
                    tooltip: isEnglish ? 'Add city' : 'Добавить город',
                  ),
                  children: country.children.asMap().entries.map((cityEntry) {
                    final cityIndex = cityEntry.key;
                    final city = cityEntry.value;
                    return ExpansionTile(
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(city.name),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteCity(countryIndex, cityIndex),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: isEnglish ? 'Add location' : 'Добавить локацию',
                        onPressed: () => _addLocation(countryIndex, cityIndex),
                      ),
                      children: city.children.asMap().entries.map((locationEntry) {
                        final locationIndex = locationEntry.key;
                        final location = locationEntry.value;
                        return ListTile(
                          title: Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Text(location.name),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _deleteLocation(countryIndex, cityIndex, locationIndex),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCountry,
        child: const Icon(Icons.add),
        tooltip: isEnglish ? 'Add country' : 'Добавить страну',
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  final String title;
  final Function(String name) onAdd;

  const _AddLocationDialog({
    required this.title,
    required this.onAdd,
  });

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter name',
        ),
        autofocus: true,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

