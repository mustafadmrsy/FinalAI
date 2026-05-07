class LearningLessonModel {
  const LearningLessonModel({
    required this.id,
    required this.userId,
    required this.unitIndex,
    required this.lessonIndex,
    required this.title,
    required this.description,
    required this.taskType,
    required this.taskContent,
    required this.isLocked,
    required this.progress,
  });

  final String id;
  final String userId;
  final int unitIndex;
  final int lessonIndex;
  final String title;
  final String description;
  final String taskType; // 'matching', 'multiple_choice', 'true_false'
  final Map<String, dynamic> taskContent; // flex json for task specifics
  final bool isLocked;
  final double progress; // 0.0 to 1.0

  factory LearningLessonModel.fromMap(Map<String, dynamic> map) {
    return LearningLessonModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      unitIndex: (map['unit_index'] as num).toInt(),
      lessonIndex: (map['lesson_index'] as num).toInt(),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      taskType: (map['task_type'] as String?) ?? 'matching',
      taskContent: (map['task_content'] as Map<String, dynamic>?) ?? {},
      isLocked: (map['is_locked'] as bool?) ?? false,
      progress: ((map['progress'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'unit_index': unitIndex,
      'lesson_index': lessonIndex,
      'title': title,
      'description': description,
      'task_type': taskType,
      'task_content': taskContent,
      'is_locked': isLocked,
      'progress': progress,
    };
  }

  LearningLessonModel copyWith({
    String? id,
    String? userId,
    int? unitIndex,
    int? lessonIndex,
    String? title,
    String? description,
    String? taskType,
    Map<String, dynamic>? taskContent,
    bool? isLocked,
    double? progress,
  }) {
    return LearningLessonModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      unitIndex: unitIndex ?? this.unitIndex,
      lessonIndex: lessonIndex ?? this.lessonIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      taskContent: taskContent ?? this.taskContent,
      isLocked: isLocked ?? this.isLocked,
      progress: progress ?? this.progress,
    );
  }
}
