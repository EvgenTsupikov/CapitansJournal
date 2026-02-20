class Note {
  String text;
  DateTime createdAt;

  Note({required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    text: json['text'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
