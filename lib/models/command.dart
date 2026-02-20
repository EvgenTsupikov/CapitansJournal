// lib/models/command.dart
//
// Модель для хранения команд (например, #location, #state и т.д.)
// Поддерживает иерархическую структуру: страна -> город -> локация

class LocationValue {
  /// Название локации (страна, город или конкретная локация)
  final String name;
  
  /// Дочерние локации (для стран - города, для городов - конкретные локации)
  final List<LocationValue> children;
  
  LocationValue({
    required this.name,
    this.children = const [],
  });
  
  /// Создает локацию из JSON
  factory LocationValue.fromJson(Map<String, dynamic> json) {
    return LocationValue(
      name: json['name'] as String,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => LocationValue.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  /// Преобразует локацию в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
  
  /// Получает полный путь локации (страна > город > локация)
  String getFullPath() {
    return name;
  }
  
  /// Получает все возможные пути (для плоского списка)
  List<String> getAllPaths({String prefix = ''}) {
    final currentPath = prefix.isEmpty ? name : '$prefix > $name';
    final paths = <String>[currentPath];
    
    for (final child in children) {
      paths.addAll(child.getAllPaths(prefix: currentPath));
    }
    
    return paths;
  }
}

class Command {
  /// Имя команды (например, "location", "state")
  final String name;
  
  /// Иерархическая структура значений (страны -> города -> локации)
  final List<LocationValue> values;
  
  Command({
    required this.name,
    required this.values,
  });
  
  /// Создает команду из JSON
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      name: json['name'] as String,
      values: (json['values'] as List<dynamic>?)
          ?.map((e) => LocationValue.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  /// Преобразует команду в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'values': values.map((e) => e.toJson()).toList(),
    };
  }
  
  /// Получает все возможные пути в плоском виде
  List<String> getAllPaths() {
    final paths = <String>[];
    for (final value in values) {
      paths.addAll(value.getAllPaths());
    }
    return paths;
  }
  
  /// Создает копию команды с измененными значениями
  Command copyWith({
    String? name,
    List<LocationValue>? values,
  }) {
    return Command(
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }
}

