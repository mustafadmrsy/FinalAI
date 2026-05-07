import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../models/note_model.dart';
import '../../../core/services/haptic_service.dart';

final recentNotesForQuizProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(noteRepositoryProvider).getRecentNotes(limit: 50);
});

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesForQuizProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: notes.when(
          loading: () => const Center(child: LoadingIndicator(message: 'Notlar yükleniyor...')),
          error: (e, _) => Center(
            child: EmptyState(
              title: 'Notlar yüklenemedi',
              message: e.toString(),
              icon: Icons.error_outline,
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: EmptyState(
                  title: 'Henüz not yok',
                  message: 'PDF yükleyerek quiz oluşturabilirsin.',
                  icon: Icons.psychology_outlined,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quiz Seç',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        '${list.length} not',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withAlpha((0.82 * 255).round()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.xl,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.18 * 255).round()),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha((0.35 * 255).round()), width: 2),
                        ),
                        child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hazır mısın?',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bir not seç, hemen quiz\'e başla',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withAlpha((0.9 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white.withAlpha((0.95 * 255).round())),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Notlar',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                ...list.map(
                  (n) => _QuizListItem(note: n, borderColor: theme.dividerColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuizListItem extends StatelessWidget {
  const _QuizListItem({required this.note, required this.borderColor});

  final NoteModel note;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BaseCard(
        onTap: () { Haptic.light(); context.push('/quiz/${note.id}'); },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.quiz_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.subject,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.createdAt.toString().substring(0, 10),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
