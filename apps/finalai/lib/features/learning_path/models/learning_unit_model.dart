class LearningUnitModel {
  const LearningUnitModel({
    required this.id,
    required this.userId,
    required this.index,
    required this.title,
    required this.description,
    required this.isLocked,
    required this.progress,
  });

  final String id;
  final String userId;
  final int index;
  final String title;
  final String description;
  final bool isLocked;
  final double progress;

  factory LearningUnitModel.fromMap(Map<String, dynamic> map) {
    return LearningUnitModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      index: (map['unit_index'] as num).toInt(),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      isLocked: (map['is_locked'] as bool?) ?? false,
      progress: ((map['progress'] as num?) ?? 0).toDouble(),
    );
  }
}
