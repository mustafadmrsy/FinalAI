import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard({int limit = 50}) async {
    try {
      final res = await _client
          .from('weekly_leaderboard')
          .select('*')
          .order('rank', ascending: true)
          .limit(limit);

      return (res as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e) {
      // Table may not exist yet; keep a meaningful error.
      throw Exception('LeaderboardRepository.getWeeklyLeaderboard failed: $e');
    }
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
