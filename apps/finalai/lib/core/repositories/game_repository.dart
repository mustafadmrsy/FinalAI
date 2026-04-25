import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepository {
  GameRepository(this._client);

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    return userId;
  }

  Future<void> createGameSession({
    required String noteId,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    try {
      final userId = _requireUserId();
      final scorePercent = totalQuestions == 0 ? 0 : ((correctAnswers / totalQuestions) * 100).round();
      await _client.from('quiz_sessions').insert({
        'user_id': userId,
        'note_id': noteId,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'score_percent': scorePercent,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('GameRepository.createGameSession failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGameHistory({int limit = 20}) async {
    try {
      final userId = _requireUserId();
      final res = await _client
          .from('quiz_sessions')
          .select('id, note_id, total_questions, correct_answers, score_percent, completed_at')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);

      return (res as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e) {
      throw Exception('GameRepository.getGameHistory failed: $e');
    }
  }
}
