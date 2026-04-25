import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/repository_providers.dart';

final recentNotesForQuizProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(noteRepositoryProvider).getRecentNotes(limit: 50);
});

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesForQuizProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Seç')),
      body: notes.when(
        loading: () => const LoadingIndicator(message: 'Notlar yükleniyor...'),
        error: (e, _) => EmptyState(
          title: 'Notlar yüklenemedi',
          message: e.toString(),
          icon: Icons.error_outline,
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'Henüz not yok',
              message: 'PDF yükleyerek quiz oluşturabilirsin.',
              icon: Icons.psychology_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final note = list[i];
              return BaseCard(
                onTap: () => context.push('/quiz/${note.id}'),
                child: Row(
                  children: [
                    const Icon(Icons.quiz_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.subject,
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            note.createdAt.toString().substring(0, 10),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
