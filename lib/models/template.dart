// lib/models/template.dart
class Template {
  final String id;
  final String name; // "утро" или "вечер"
  final String location; // "локация"
  final String state; // "состояние"
  final String practices; // "практики"

  Template({
    required this.id,
    required this.name,
    required this.location,
    required this.state,
    required this.practices,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'state': state,
    'practices': practices,
  };

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json['id'],
    name: json['name'],
    location: json['location'],
    state: json['state'],
    practices: json['practices'],
  );

  String generateText() {
    final buffer = StringBuffer();
    buffer.writeln(name);
    if (location.isNotEmpty) {
      buffer.writeln('Локация: $location');
    }
    if (state.isNotEmpty) {
      buffer.writeln('Состояние: $state');
    }
    if (practices.isNotEmpty) {
      buffer.writeln('Практики: $practices');
    }
    return buffer.toString().trim();
  }
}

