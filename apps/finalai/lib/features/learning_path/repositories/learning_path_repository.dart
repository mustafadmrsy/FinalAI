import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learning_unit_model.dart';
import '../models/learning_lesson_model.dart';
import '../services/ai_plan_generator.dart';

class LearningPathRepository {
  LearningPathRepository(this._client);

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    return userId;
  }

  Future<bool> isOnboardingCompleted() async {
    final userId = _requireUserId();

    // 1) Check profile flag
    final res = await _client
        .from('user_profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return false;
    final flagDone = (res['onboarding_completed'] as bool?) ?? false;
    if (!flagDone) return false;

    // 2) Also verify learning_units actually exist (guard against stale flag)
    final units = await _client
        .from('learning_units')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return (units as List).isNotEmpty;
  }

  Future<void> saveOnboarding({required String subject, required String difficulty}) async {
    final userId = _requireUserId();
    await _client.from('user_profiles').upsert(
      {
        'id': userId,
        'learning_subject': subject,
        'learning_difficulty': difficulty,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  Future<void> generateAndSaveInitialPlan({
    required String subject,
    required String difficulty,
    String goal = '',
    int dailyMinutes = 15,
  }) async {
    final userId = _requireUserId();

    // AI generates the plan — no static fallback
    final plan = await AiPlanGenerator.generatePlan(
      subject: subject,
      difficulty: difficulty,
      goal: goal,
      dailyMinutes: dailyMinutes,
    );

    final aiUnits = (plan['units'] as List?) ?? [];
    final now = DateTime.now().toIso8601String();

    // Save units
    final unitRows = <Map<String, dynamic>>[];
    for (int i = 0; i < aiUnits.length; i++) {
      final u = aiUnits[i] as Map<String, dynamic>;
      final idx = (u['unit_index'] as int?) ?? (i + 1);
      unitRows.add({
        'user_id': userId,
        'unit_index': idx,
        'title': (u['title'] as String?) ?? 'Unite $idx',
        'description': (u['description'] as String?) ?? '$subject',
        'is_locked': idx != 1,
        'progress': 0,
        'created_at': now,
        'updated_at': now,
      });
    }

    if (unitRows.isEmpty) {
      throw Exception('AI ünite üretilemedi.');
    }

    await _client.from('learning_units').upsert(unitRows, onConflict: 'user_id,unit_index');

    // Save lessons from AI output
    final allLessons = <Map<String, dynamic>>[];
    for (int i = 0; i < aiUnits.length; i++) {
      final u = aiUnits[i] as Map<String, dynamic>;
      final unitIdx = (u['unit_index'] as int?) ?? (i + 1);
      final lessons = (u['lessons'] as List?) ?? [];

      for (int j = 0; j < lessons.length; j++) {
        final l = lessons[j] as Map<String, dynamic>;
        final lessonIdx = (l['lesson_index'] as int?) ?? (j + 1);
        allLessons.add({
          'user_id': userId,
          'unit_index': unitIdx,
          'lesson_index': lessonIdx,
          'title': (l['title'] as String?) ?? 'Ders $lessonIdx',
          'description': (l['description'] as String?) ?? '',
          'task_type': (l['task_type'] as String?) ?? 'matching',
          'task_content': l['task_content'] ?? {},
          'is_locked': !(unitIdx == 1 && lessonIdx == 1),
          'progress': 0.0,
          'created_at': now,
          'updated_at': now,
        });
      }
    }

    if (allLessons.isEmpty) {
      throw Exception('AI ders içeriği üretilemedi.');
    }

    await _client.from('learning_lessons').upsert(
      allLessons,
      onConflict: 'user_id,unit_index,lesson_index',
    );
  }

  Future<({String subject, String difficulty})> _getUserLearningPrefs() async {
    final userId = _requireUserId();
    final res = await _client
        .from('user_profiles')
        .select('learning_subject, learning_difficulty')
        .eq('id', userId)
        .maybeSingle();

    final subject = (res?['learning_subject'] as String?) ?? 'Genel';
    final difficulty = (res?['learning_difficulty'] as String?) ?? 'Başlangıç';
    return (subject: subject, difficulty: difficulty);
  }

  Future<List<LearningUnitModel>> getUnits() async {
    final userId = _requireUserId();
    final res = await _client
        .from('learning_units')
        .select('id, user_id, unit_index, title, description, is_locked, progress')
        .eq('user_id', userId)
        .order('unit_index');

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(LearningUnitModel.fromMap).toList();
  }

  /// Get all lessons for a specific unit
  Future<List<LearningLessonModel>> getLessonsByUnit(int unitIndex) async {
    final userId = _requireUserId();
    var res = await _client
        .from('learning_lessons')
        .select('id, user_id, unit_index, lesson_index, title, description, task_type, task_content, is_locked, progress')
        .eq('user_id', userId)
        .eq('unit_index', unitIndex)
        .order('lesson_index');

    var list = (res as List).cast<Map<String, dynamic>>();
    if (list.isNotEmpty) {
      return list.map(LearningLessonModel.fromMap).toList();
    }

    // If user was onboarded before lesson seeding existed, regenerate with AI.
    final prefs = await _getUserLearningPrefs();
    await generateAndSaveInitialPlan(
      subject: prefs.subject,
      difficulty: prefs.difficulty,
    );

    res = await _client
        .from('learning_lessons')
        .select('id, user_id, unit_index, lesson_index, title, description, task_type, task_content, is_locked, progress')
        .eq('user_id', userId)
        .eq('unit_index', unitIndex)
        .order('lesson_index');
    list = (res as List).cast<Map<String, dynamic>>();
    return list.map(LearningLessonModel.fromMap).toList();
  }

  /// Mark a lesson as completed (progress=1) and unlock the next lesson
  /// If this was the last lesson, unlock the next unit + its first lesson
  Future<void> completeLessonAndUnlockNext(int unitIndex, int lessonIndex) async {
    final userId = _requireUserId();
    final now = DateTime.now().toIso8601String();

    // Mark current lesson as complete
    await _client
        .from('learning_lessons')
        .update({'progress': 1.0, 'updated_at': now})
        .eq('user_id', userId)
        .eq('unit_index', unitIndex)
        .eq('lesson_index', lessonIndex);

    // Try to unlock the next lesson in the same unit
    final nextLesson = await _client
        .from('learning_lessons')
        .select('id')
        .eq('user_id', userId)
        .eq('unit_index', unitIndex)
        .eq('lesson_index', lessonIndex + 1)
        .maybeSingle();

    if (nextLesson != null) {
      // Unlock next lesson in this unit
      await _client
          .from('learning_lessons')
          .update({'is_locked': false, 'updated_at': now})
          .eq('user_id', userId)
          .eq('unit_index', unitIndex)
          .eq('lesson_index', lessonIndex + 1);
    }

    // Her zaman unite ilerlemesini guncelle
    await _updateUnitProgressAndUnlockNext(unitIndex);
  }

  /// Calculate unit progress based on lesson completion
  /// If unit is complete, unlock the next unit AND its first lesson
  Future<void> _updateUnitProgressAndUnlockNext(int unitIndex) async {
    final userId = _requireUserId();
    final now = DateTime.now().toIso8601String();

    // Get all lessons for this unit
    final lessons = await getLessonsByUnit(unitIndex);
    final completedCount = lessons.where((l) => l.progress == 1.0).length;
    final totalCount = lessons.length;
    final unitProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

    // Update unit progress
    await _client
        .from('learning_units')
        .update({'progress': unitProgress, 'updated_at': now})
        .eq('user_id', userId)
        .eq('unit_index', unitIndex);

    // If unit is complete, unlock the next unit AND its first lesson
    if (unitProgress >= 1.0) {
      final nextUnitIndex = unitIndex + 1;

      // Sonraki uniteyi ac
      await _client
          .from('learning_units')
          .update({'is_locked': false, 'updated_at': now})
          .eq('user_id', userId)
          .eq('unit_index', nextUnitIndex);

      // Sonraki unitenin ilk dersini ac
      await _client
          .from('learning_lessons')
          .update({'is_locked': false, 'updated_at': now})
          .eq('user_id', userId)
          .eq('unit_index', nextUnitIndex)
          .eq('lesson_index', 1);
    }
  }

  /// Regenerate the entire learning plan using AI.
  /// Deletes existing lessons and units, then generates fresh ones.
  Future<void> regeneratePlanWithAi() async {
    final userId = _requireUserId();
    final prefs = await _getUserLearningPrefs();

    // Delete existing lessons and units
    await _client.from('learning_lessons').delete().eq('user_id', userId);
    await _client.from('learning_units').delete().eq('user_id', userId);

    // Re-generate using AI
    await generateAndSaveInitialPlan(
      subject: prefs.subject,
      difficulty: prefs.difficulty,
    );
  }
}
