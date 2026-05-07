import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/repository_providers.dart';
import '../repositories/learning_path_repository.dart';
import '../models/learning_unit_model.dart';
import '../models/learning_lesson_model.dart';

final learningPathRepositoryProvider = Provider<LearningPathRepository>((ref) {
  return LearningPathRepository(ref.watch(supabaseClientProvider));
});

/// Re-evaluates whenever auth state changes (sign-in / sign-up / sign-out)
final onboardingCompletedProvider = FutureProvider.autoDispose<bool>((ref) async {
  // Depend on auth uid so provider auto-refetches on login/signup/logout
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  return ref.watch(learningPathRepositoryProvider).isOnboardingCompleted();
});

/// Re-evaluates whenever auth state changes so each user sees their own units
final learningUnitsProvider = FutureProvider.autoDispose<List<LearningUnitModel>>((ref) async {
  // Depend on auth uid so provider auto-refetches on login/signup/logout
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  return ref.watch(learningPathRepositoryProvider).getUnits();
});

/// Get lessons for a specific unit by unitIndex
/// Re-evaluates on auth change so each user sees their own lessons
final learningLessonsByUnitProvider = FutureProvider.autoDispose.family<List<LearningLessonModel>, int>((ref, unitIndex) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  return ref.watch(learningPathRepositoryProvider).getLessonsByUnit(unitIndex);
});
