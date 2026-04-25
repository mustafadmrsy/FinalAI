import 'package:supabase_flutter/supabase_flutter.dart';

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    return userId;
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _requireUserId();
      final res = await _client
          .from('user_stats')
          .select('total_pdfs, total_questions_answered, correct_answers, study_streak, last_study_date')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) {
        return {
          'total_pdfs': 0,
          'total_questions_answered': 0,
          'correct_answers': 0,
          'study_streak': 0,
          'last_study_date': null,
        };
      }
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      throw Exception('StatsRepository.getUserStats failed: $e');
    }
  }

  Future<void> upsertUserStats(Map<String, dynamic> updates) async {
    try {
      final userId = _requireUserId();
      await _client.from('user_stats').upsert(
        {
          'user_id': userId,
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('StatsRepository.upsertUserStats failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _requireUserId();
      final res = await _client
          .from('user_profiles')
          .select('id, full_name, avatar_url, is_premium, premium_until, daily_upload_count, last_upload_date')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      throw Exception('StatsRepository.getUserProfile failed: $e');
    }
  }

  Future<void> updateUserProfile({String? fullName}) async {
    try {
      final userId = _requireUserId();
      final payload = <String, dynamic>{
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) payload['full_name'] = fullName;

      await _client.from('user_profiles').upsert(payload, onConflict: 'id');
    } catch (e) {
      throw Exception('StatsRepository.updateUserProfile failed: $e');
    }
  }

  Future<void> upsertUserProfileFields(Map<String, dynamic> updates) async {
    try {
      final userId = _requireUserId();
      await _client.from('user_profiles').upsert(
        {
          'id': userId,
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e) {
      throw Exception('StatsRepository.upsertUserProfileFields failed: $e');
    }
  }
}
