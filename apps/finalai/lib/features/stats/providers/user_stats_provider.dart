import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/repository_providers.dart';
import '../models/user_stats_model.dart';
import '../../notifications/services/notification_service.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return UserStatsRepository(ref.watch(supabaseClientProvider));
});

final userStatsProvider = FutureProvider<UserStatsModel?>((ref) async {
  return ref.watch(userStatsRepositoryProvider).getUserStats();
});

// ============================================================================
// REPOSITORY
// ============================================================================

class UserStatsRepository {
  UserStatsRepository(this._client);

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    return userId;
  }

  /// Get or create user stats
  Future<UserStatsModel?> getUserStats() async {
    final userId = _requireUserId();
    final res = await _client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) {
      // İlk defa → create default stats
      await _createDefaultStats(userId);
      return await getUserStats();
    }

    return UserStatsModel.fromMap(res as Map<String, dynamic>);
  }

  /// Create default stats for new user
  Future<void> _createDefaultStats(String userId) async {
    await _client.from('user_stats').insert({
      'user_id': userId,
      'xp_total': 0,
      'xp_today': 0,
      'energy': 30,
      'energy_max': 30,
      'last_energy_reset': DateTime.now().toIso8601String(),
      'combo_current': 0,
      'combo_best': 0,
      'last_active_date': DateTime.now().toIso8601String(),
      'is_premium': false,
      'streak_freeze_available': true,
      'daily_quest_lessons': 0,
      'daily_quest_lessons_goal': 3,
      'daily_quest_xp': 0,
      'daily_quest_xp_goal': 50,
      'daily_quest_correct': 0,
      'daily_quest_correct_goal': 10,
      'daily_quest_streak': 0,
      'ai_tokens': 5,
      'pdf_credits': 3,
    });
  }

  /// Update XP and combo after lesson completion
  Future<void> updateXpAndCombo({
    required int xpGain,
    required int comboIncrease,
  }) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) throw Exception('Stats not found');

    final newComboCurrent = stats.comboCurrent + comboIncrease;
    final newComboBest = newComboCurrent > stats.comboBest ? newComboCurrent : stats.comboBest;

    await _client.from('user_stats').update({
      'xp_total': stats.xpTotal + xpGain,
      'xp_today': stats.xpToday + xpGain,
      'combo_current': newComboCurrent,
      'combo_best': newComboBest,
      'last_active_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Use energy (when lesson starts)
  Future<void> useEnergy({required int amount}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) throw Exception('Stats not found');

    if (stats.energy < amount) {
      throw Exception('Not enough energy');
    }

    await _client.from('user_stats').update({
      'energy': stats.energy - amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Add energy (combo reward)
  Future<void> addEnergy({required int amount}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) throw Exception('Stats not found');

    final newEnergy = (stats.energy + amount).clamp(0, stats.energyMax + 10);
    await _client.from('user_stats').update({
      'energy': newEnergy,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Reset daily (energy, xp_today, combo if streak broken)
  Future<void> dailyReset() async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) throw Exception('Stats not found');

    // Premium users get 2x energy
    final energyMax = stats.isPremium ? 60 : 30;

    await _client.from('user_stats').update({
      'energy': energyMax,
      'energy_max': energyMax,
      'xp_today': 0,
      'last_energy_reset': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    // Enerji doldu bildirimi gonder
    try { await NotificationService.notifyEnergyFull(); } catch (e) { debugPrint('Energy notif error: $e'); }
  }

  /// Update streak (called on daily reset or lesson completion)
  Future<void> updateStreak({required int newStreak}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) throw Exception('Stats not found');

    final newLongestStreak = newStreak > (stats.longestStreak ?? 0) ? newStreak : stats.longestStreak;

    await _client.from('user_stats').update({
      'study_streak': newStreak,
      'longest_streak': newLongestStreak,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // ═══════════════════════════════════════════════════════
  //  STREAK LOGIC — 24h mantigi + freeze
  // ═══════════════════════════════════════════════════════

  /// Enum-like return: 'continued' | 'frozen' | 'broken'
  Future<String> checkAndUpdateStreak() async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return 'broken';

    final now = DateTime.now();
    final lastActive = stats.lastActiveDate;
    if (lastActive == null) {
      // Ilk giris
      await _client.from('user_stats').update({
        'study_streak': 1,
        'longest_streak': 1,
        'last_active_date': now.toIso8601String(),
        'last_study_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('user_id', userId);
      return 'continued';
    }

    final diff = now.difference(lastActive);
    final daysSince = diff.inHours ~/ 24;

    if (daysSince < 1) {
      // Ayni gun — seri degismez
      return 'continued';
    }

    if (daysSince == 1) {
      // 24-48 saat arasi — seri devam
      final newStreak = (stats.studyStreak ?? 0) + 1;
      final newLongest = newStreak > (stats.longestStreak ?? 0) ? newStreak : (stats.longestStreak ?? 0);
      await _client.from('user_stats').update({
        'study_streak': newStreak,
        'longest_streak': newLongest,
        'last_active_date': now.toIso8601String(),
        'last_study_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('user_id', userId);
      return 'continued';
    }

    if (daysSince == 2 && stats.streakFreezeAvailable) {
      // 48-72 saat arasi + freeze haki var — seriyi dondur
      await _client.from('user_stats').update({
        'streak_freeze_available': false,
        'last_active_date': now.toIso8601String(),
        'last_study_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('user_id', userId);
      // Seri donduruldu bildirimi
      try { await NotificationService.notifyStreakFrozen(streakCount: stats.studyStreak ?? 0); } catch (_) {}
      return 'frozen';
    }

    // Seri kirildi
    await _client.from('user_stats').update({
      'study_streak': 1,
      'streak_freeze_available': true,
      'last_active_date': now.toIso8601String(),
      'last_study_date': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('user_id', userId);
    // Seri kirildi bildirimi
    try { await NotificationService.notifyStreakBroken(); } catch (_) {}
    return 'broken';
  }

  /// Test: seriyi dondurma durumuna getir (profil test butonu icin)
  Future<void> debugSimulateStreakFreeze() async {
    final userId = _requireUserId();
    final now = DateTime.now();
    // last_active_date'i 2 gun geriye al
    await _client.from('user_stats').update({
      'last_active_date': now.subtract(const Duration(hours: 50)).toIso8601String(),
      'streak_freeze_available': true,
      'updated_at': now.toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Test: seriyi kirilmis durumuna getir
  Future<void> debugSimulateStreakBroken() async {
    final userId = _requireUserId();
    final now = DateTime.now();
    await _client.from('user_stats').update({
      'last_active_date': now.subtract(const Duration(hours: 100)).toIso8601String(),
      'streak_freeze_available': false,
      'updated_at': now.toIso8601String(),
    }).eq('user_id', userId);
  }

  // ═══════════════════════════════════════════════════════
  //  DAILY QUEST LOGIC
  // ═══════════════════════════════════════════════════════

  /// Gunluk gorevleri kontrol et, yeni gundeyse resetle
  Future<void> checkAndResetDailyQuests() async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return;

    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (stats.dailyQuestsResetDate == today) return; // Ayni gun

    // Yeni gun — gunluk gorevleri resetle
    // Eger dunku gorev tamamlandiysa streak artar, yoksa 0'a doner
    final allDone = stats.dailyQuestLessons >= stats.dailyQuestLessonsGoal &&
        stats.dailyQuestXp >= stats.dailyQuestXpGoal &&
        stats.dailyQuestCorrect >= stats.dailyQuestCorrectGoal;
    final newQuestStreak = allDone ? stats.dailyQuestStreak + 1 : 0;

    await _client.from('user_stats').update({
      'daily_quest_lessons': 0,
      'daily_quest_xp': 0,
      'daily_quest_correct': 0,
      'daily_quest_streak': newQuestStreak,
      'daily_quests_reset_date': today,
      'updated_at': now.toIso8601String(),
    }).eq('user_id', userId);

    // Enerji reset (yeni gun)
    final energyMax = stats.isPremium ? 60 : 30;
    await _client.from('user_stats').update({
      'energy': energyMax,
      'energy_max': energyMax,
      'xp_today': 0,
      'last_energy_reset': now.toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Gunluk gorev ilerlemesi guncelle
  Future<void> incrementDailyQuest({int lessons = 0, int xp = 0, int correct = 0}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return;

    await _client.from('user_stats').update({
      'daily_quest_lessons': stats.dailyQuestLessons + lessons,
      'daily_quest_xp': stats.dailyQuestXp + xp,
      'daily_quest_correct': stats.dailyQuestCorrect + correct,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // ═══════════════════════════════════════════════════════
  //  PREMIUM & PURCHASE LOGIC
  // ═══════════════════════════════════════════════════════

  /// Premium durumunu guncelle
  Future<void> setPremium(bool value) async {
    final userId = _requireUserId();
    await _client.from('user_stats').update({
      'is_premium': value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // ═══════════════════════════════════════════════════════
  //  AI TOKEN & PDF CREDIT LOGIC
  // ═══════════════════════════════════════════════════════

  /// AI token kullan (plan olusturma vs.)
  Future<bool> useAiToken({int amount = 1}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return false;
    if (stats.isPremium) return true; // Premium = sinirsiz
    if (stats.aiTokens < amount) return false;

    await _client.from('user_stats').update({
      'ai_tokens': stats.aiTokens - amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
    return true;
  }

  /// PDF kredi kullan
  Future<bool> usePdfCredit() async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return false;
    if (stats.isPremium) return true; // Premium = sinirsiz
    if (stats.pdfCredits <= 0) return false;

    await _client.from('user_stats').update({
      'pdf_credits': stats.pdfCredits - 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
    return true;
  }

  /// Reklam izleme odulu: +1 PDF kredi
  Future<void> rewardPdfCredit() async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return;

    await _client.from('user_stats').update({
      'pdf_credits': stats.pdfCredits + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Reklam izleme odulu: +2 AI token
  Future<void> rewardAiTokens({int amount = 2}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return;

    await _client.from('user_stats').update({
      'ai_tokens': stats.aiTokens + amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Reklam izleme odulu: +3 enerji
  Future<void> rewardEnergy({int amount = 3}) async {
    final userId = _requireUserId();
    final stats = await getUserStats();
    if (stats == null) return;

    final newEnergy = (stats.energy + amount).clamp(0, stats.energyMax + 10);
    await _client.from('user_stats').update({
      'energy': newEnergy,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }
}
