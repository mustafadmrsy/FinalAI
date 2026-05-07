import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../core/repositories/leaderboard_repository.dart';

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  return ref.watch(leaderboardRepositoryProvider).getGlobalLeaderboard(limit: 100);
});

final subjectLeaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, subject) async {
  if (subject.isEmpty) {
    return ref.watch(leaderboardRepositoryProvider).getGlobalLeaderboard(limit: 100);
  }
  return ref.watch(leaderboardRepositoryProvider).getSubjectLeaderboard(subject, limit: 100);
});

/// Current user's learning subject from profile
final userLearningSubjectProvider = FutureProvider.autoDispose<String>((ref) async {
  final profile = await ref.watch(statsRepositoryProvider).getUserProfile();
  return (profile?['learning_subject'] as String?) ?? '';
});
