class NoteModel {
  const NoteModel({
    required this.id,
    required this.subject,
    required this.filePath,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String? filePath;
  final DateTime createdAt;

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      filePath: json['file_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
