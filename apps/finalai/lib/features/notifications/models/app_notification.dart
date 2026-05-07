// ═══════════════════════════════════════════════════════════════
//  APP NOTIFICATION MODEL — Uygulama ici bildirim verisi
// ═══════════════════════════════════════════════════════════════

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.data,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? data;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id, type: type, title: title, body: body, createdAt: createdAt,
    read: read ?? this.read, data: data,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'title': title, 'body': body,
    'createdAt': createdAt.toIso8601String(), 'read': read,
    if (data != null) 'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: NotificationType.values.firstWhere((t) => t.name == json['type'], orElse: () => NotificationType.general),
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: (json['read'] as bool?) ?? false,
    data: json['data'] as Map<String, dynamic>?,
  );
}

enum NotificationType {
  energyFull,
  streakReminder,
  streakFrozen,
  streakBroken,
  dailyTip,
  achievement,
  xpEarned,
  dailyQuest,
  pdfUpload,
  pdfSummary,
  general,
}
