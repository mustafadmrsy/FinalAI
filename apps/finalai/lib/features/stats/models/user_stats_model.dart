class UserStatsModel {
  const UserStatsModel({
    required this.id,
    required this.userId,
    required this.totalPdfs,
    required this.totalQuestionsAnswered,
    required this.correctAnswers,
    required this.studyStreak,
    required this.longestStreak,
    required this.lastStudyDate,
    required this.xpTotal,
    required this.xpToday,
    required this.energy,
    required this.energyMax,
    required this.lastEnergyReset,
    required this.comboCurrent,
    required this.comboBest,
    required this.lastActiveDate,
    required this.isPremium,
    required this.streakFreezeAvailable,
    required this.dailyQuestLessons,
    required this.dailyQuestLessonsGoal,
    required this.dailyQuestXp,
    required this.dailyQuestXpGoal,
    required this.dailyQuestCorrect,
    required this.dailyQuestCorrectGoal,
    required this.dailyQuestStreak,
    required this.dailyQuestsResetDate,
    required this.aiTokens,
    required this.pdfCredits,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final int? totalPdfs;
  final int? totalQuestionsAnswered;
  final int? correctAnswers;
  final int? studyStreak;
  final int? longestStreak;
  final DateTime? lastStudyDate;
  final int xpTotal;
  final int xpToday;
  final int energy;
  final int energyMax;
  final DateTime lastEnergyReset;
  final int comboCurrent;
  final int comboBest;
  final DateTime? lastActiveDate;
  final bool isPremium;
  final bool streakFreezeAvailable;
  final int dailyQuestLessons;
  final int dailyQuestLessonsGoal;
  final int dailyQuestXp;
  final int dailyQuestXpGoal;
  final int dailyQuestCorrect;
  final int dailyQuestCorrectGoal;
  final int dailyQuestStreak;
  final String? dailyQuestsResetDate;
  final int aiTokens;
  final int pdfCredits;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserStatsModel.fromMap(Map<String, dynamic> map) {
    return UserStatsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      totalPdfs: (map['total_pdfs'] as num?)?.toInt(),
      totalQuestionsAnswered: (map['total_questions_answered'] as num?)?.toInt(),
      correctAnswers: (map['correct_answers'] as num?)?.toInt(),
      studyStreak: (map['study_streak'] as num?)?.toInt(),
      longestStreak: (map['longest_streak'] as num?)?.toInt(),
      lastStudyDate: map['last_study_date'] != null ? DateTime.parse(map['last_study_date'] as String) : null,
      xpTotal: (map['xp_total'] as num?)?.toInt() ?? 0,
      xpToday: (map['xp_today'] as num?)?.toInt() ?? 0,
      energy: (map['energy'] as num?)?.toInt() ?? 30,
      energyMax: (map['energy_max'] as num?)?.toInt() ?? 30,
      lastEnergyReset: map['last_energy_reset'] != null ? DateTime.parse(map['last_energy_reset'] as String) : DateTime.now(),
      comboCurrent: (map['combo_current'] as num?)?.toInt() ?? 0,
      comboBest: (map['combo_best'] as num?)?.toInt() ?? 0,
      lastActiveDate: map['last_active_date'] != null ? DateTime.parse(map['last_active_date'] as String) : null,
      isPremium: (map['is_premium'] as bool?) ?? false,
      streakFreezeAvailable: (map['streak_freeze_available'] as bool?) ?? true,
      dailyQuestLessons: (map['daily_quest_lessons'] as num?)?.toInt() ?? 0,
      dailyQuestLessonsGoal: (map['daily_quest_lessons_goal'] as num?)?.toInt() ?? 3,
      dailyQuestXp: (map['daily_quest_xp'] as num?)?.toInt() ?? 0,
      dailyQuestXpGoal: (map['daily_quest_xp_goal'] as num?)?.toInt() ?? 50,
      dailyQuestCorrect: (map['daily_quest_correct'] as num?)?.toInt() ?? 0,
      dailyQuestCorrectGoal: (map['daily_quest_correct_goal'] as num?)?.toInt() ?? 10,
      dailyQuestStreak: (map['daily_quest_streak'] as num?)?.toInt() ?? 0,
      dailyQuestsResetDate: map['daily_quests_reset_date'] as String?,
      aiTokens: (map['ai_tokens'] as num?)?.toInt() ?? 5,
      pdfCredits: (map['pdf_credits'] as num?)?.toInt() ?? 3,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total_pdfs': totalPdfs,
      'total_questions_answered': totalQuestionsAnswered,
      'correct_answers': correctAnswers,
      'study_streak': studyStreak,
      'longest_streak': longestStreak,
      'last_study_date': lastStudyDate?.toIso8601String(),
      'xp_total': xpTotal,
      'xp_today': xpToday,
      'energy': energy,
      'energy_max': energyMax,
      'last_energy_reset': lastEnergyReset.toIso8601String(),
      'combo_current': comboCurrent,
      'combo_best': comboBest,
      'last_active_date': lastActiveDate?.toIso8601String(),
      'is_premium': isPremium,
      'streak_freeze_available': streakFreezeAvailable,
      'daily_quest_lessons': dailyQuestLessons,
      'daily_quest_lessons_goal': dailyQuestLessonsGoal,
      'daily_quest_xp': dailyQuestXp,
      'daily_quest_xp_goal': dailyQuestXpGoal,
      'daily_quest_correct': dailyQuestCorrect,
      'daily_quest_correct_goal': dailyQuestCorrectGoal,
      'daily_quest_streak': dailyQuestStreak,
      'daily_quests_reset_date': dailyQuestsResetDate,
      'ai_tokens': aiTokens,
      'pdf_credits': pdfCredits,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserStatsModel copyWith({
    String? id,
    String? userId,
    int? totalPdfs,
    int? totalQuestionsAnswered,
    int? correctAnswers,
    int? studyStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    int? xpTotal,
    int? xpToday,
    int? energy,
    int? energyMax,
    DateTime? lastEnergyReset,
    int? comboCurrent,
    int? comboBest,
    DateTime? lastActiveDate,
    bool? isPremium,
    bool? streakFreezeAvailable,
    int? dailyQuestLessons,
    int? dailyQuestLessonsGoal,
    int? dailyQuestXp,
    int? dailyQuestXpGoal,
    int? dailyQuestCorrect,
    int? dailyQuestCorrectGoal,
    int? dailyQuestStreak,
    String? dailyQuestsResetDate,
    int? aiTokens,
    int? pdfCredits,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalPdfs: totalPdfs ?? this.totalPdfs,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      studyStreak: studyStreak ?? this.studyStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      xpTotal: xpTotal ?? this.xpTotal,
      xpToday: xpToday ?? this.xpToday,
      energy: energy ?? this.energy,
      energyMax: energyMax ?? this.energyMax,
      lastEnergyReset: lastEnergyReset ?? this.lastEnergyReset,
      comboCurrent: comboCurrent ?? this.comboCurrent,
      comboBest: comboBest ?? this.comboBest,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isPremium: isPremium ?? this.isPremium,
      streakFreezeAvailable: streakFreezeAvailable ?? this.streakFreezeAvailable,
      dailyQuestLessons: dailyQuestLessons ?? this.dailyQuestLessons,
      dailyQuestLessonsGoal: dailyQuestLessonsGoal ?? this.dailyQuestLessonsGoal,
      dailyQuestXp: dailyQuestXp ?? this.dailyQuestXp,
      dailyQuestXpGoal: dailyQuestXpGoal ?? this.dailyQuestXpGoal,
      dailyQuestCorrect: dailyQuestCorrect ?? this.dailyQuestCorrect,
      dailyQuestCorrectGoal: dailyQuestCorrectGoal ?? this.dailyQuestCorrectGoal,
      dailyQuestStreak: dailyQuestStreak ?? this.dailyQuestStreak,
      dailyQuestsResetDate: dailyQuestsResetDate ?? this.dailyQuestsResetDate,
      aiTokens: aiTokens ?? this.aiTokens,
      pdfCredits: pdfCredits ?? this.pdfCredits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
