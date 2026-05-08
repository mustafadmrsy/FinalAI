import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.subject,
    required this.xpTotal,
    required this.correctAnswers,
    required this.studyStreak,
    required this.comboCurrent,
    required this.comboBest,
    required this.level,
    this.isCurrentUser = false,
  });

  final String userId;
  final String name;
  final String subject;
  final int xpTotal;
  final int correctAnswers;
  final int studyStreak;
  final int comboCurrent;
  final int comboBest;
  final int level;
  final bool isCurrentUser;

  /// Composite score for ranking: weighted sum of all metrics
  int get score => xpTotal + (correctAnswers * 10) + (studyStreak * 50) + (comboBest * 20);
}

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Global leaderboard sorted by XP
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 50}) async {
    try {
      final res = await _client
          .from('user_stats')
          .select('user_id, xp_total, correct_answers, study_streak, combo_current, combo_best, user_profiles!inner(full_name, learning_subject)')
          .order('xp_total', ascending: false)
          .limit(limit);

      final entries = _parseEntries(res as List);
      entries.sort((a, b) => b.score.compareTo(a.score));
      return entries;
    } catch (e) {
      // Fallback: query without join if FK not set up
      return _getLeaderboardFallback(limit: limit);
    }
  }

  /// Leaderboard filtered by learning subject
  Future<List<LeaderboardEntry>> getSubjectLeaderboard(String subject, {int limit = 50}) async {
    try {
      final res = await _client
          .from('user_stats')
          .select('user_id, xp_total, correct_answers, study_streak, combo_current, combo_best, user_profiles!inner(full_name, learning_subject)')
          .eq('user_profiles.learning_subject', subject)
          .order('xp_total', ascending: false)
          .limit(limit);

      final entries = _parseEntries(res as List);
      entries.sort((a, b) => b.score.compareTo(a.score));
      return entries;
    } catch (e) {
      return _getLeaderboardFallback(subject: subject, limit: limit);
    }
  }

  /// Fallback: separate queries when join fails
  Future<List<LeaderboardEntry>> _getLeaderboardFallback({String? subject, int limit = 50}) async {
    try {
      // user_stats tablosundan tum kullanicilari cek
      final statsRes = await _client
          .from('user_stats')
          .select('user_id, xp_total, correct_answers, study_streak, combo_current, combo_best')
          .order('xp_total', ascending: false)
          .limit(limit * 2);

      final statsList = (statsRes as List).cast<Map<String, dynamic>>();
      if (statsList.isEmpty) return [];

      final userIds = statsList.map((s) => s['user_id'] as String).toList();

      // Profile'lari toplu cek
      Map<String, Map<String, dynamic>> profileMap = {};
      try {
        var profileQuery = _client
            .from('user_profiles')
            .select('id, full_name, learning_subject')
            .inFilter('id', userIds);

        if (subject != null && subject.isNotEmpty) {
          profileQuery = profileQuery.eq('learning_subject', subject);
        }

        final profilesRes = await profileQuery;
        for (final p in (profilesRes as List).cast<Map<String, dynamic>>()) {
          profileMap[p['id'] as String] = p;
        }
      } catch (_) {
        // Profile RLS engelliyorsa, en azindan stats'dan goster
      }

      final entries = <LeaderboardEntry>[];
      for (final s in statsList) {
        final uid = s['user_id'] as String;
        final profile = profileMap[uid];
        // Profile olmasa bile kullaniciyi goster
        if (subject != null && subject.isNotEmpty && profile == null) continue;

        final xp = (s['xp_total'] as num?)?.toInt() ?? 0;
        entries.add(LeaderboardEntry(
          userId: uid,
          name: (profile?['full_name'] as String?) ?? 'Kullanici ${uid.substring(0, 4)}',
          subject: (profile?['learning_subject'] as String?) ?? '',
          xpTotal: xp,
          correctAnswers: (s['correct_answers'] as num?)?.toInt() ?? 0,
          studyStreak: (s['study_streak'] as num?)?.toInt() ?? 0,
          comboCurrent: (s['combo_current'] as num?)?.toInt() ?? 0,
          comboBest: (s['combo_best'] as num?)?.toInt() ?? 0,
          level: (xp / 500).floor() + 1,
          isCurrentUser: uid == _currentUserId,
        ));
      }

      entries.sort((a, b) => b.score.compareTo(a.score));
      return entries.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  List<LeaderboardEntry> _parseEntries(List raw) {
    final entries = <LeaderboardEntry>[];
    for (final item in raw) {
      final m = (item as Map).cast<String, dynamic>();
      final profile = (m['user_profiles'] as Map?)?.cast<String, dynamic>() ?? {};
      final uid = m['user_id'] as String;
      final xp = (m['xp_total'] as num?)?.toInt() ?? 0;

      entries.add(LeaderboardEntry(
        userId: uid,
        name: (profile['full_name'] as String?) ?? 'Anonim',
        subject: (profile['learning_subject'] as String?) ?? '',
        xpTotal: xp,
        correctAnswers: (m['correct_answers'] as num?)?.toInt() ?? 0,
        studyStreak: (m['study_streak'] as num?)?.toInt() ?? 0,
        comboCurrent: (m['combo_current'] as num?)?.toInt() ?? 0,
        comboBest: (m['combo_best'] as num?)?.toInt() ?? 0,
        level: (xp / 500).floor() + 1,
        isCurrentUser: uid == _currentUserId,
      ));
    }
    return entries;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final res = await _client
          .from('user_profiles')
          .select('id, full_name, avatar_url')
          .ilike('full_name', '%$q%')
          .limit(limit);

      return (res as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e) {
      throw Exception('LeaderboardRepository.searchUsers failed: $e');
    }
  }
}
