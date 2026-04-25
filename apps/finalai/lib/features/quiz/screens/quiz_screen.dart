import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_result/providers/note_detail_provider.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteId != null) {
      final noteAsync = ref.watch(noteDetailProvider(noteId!));
      noteAsync.whenData((data) {
        final questions = (data['questions'] as List?)?.cast<dynamic>() ?? [];
        if (questions.isNotEmpty) {
          final currentQuestions = ref.read(quizProvider).questions;
          final needsLoad = currentQuestions.isEmpty || 
              (currentQuestions.isNotEmpty && 
               currentQuestions.first.question == 'Elektrik alanın birimi nedir?');
          
          if (needsLoad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(quizProvider.notifier).loadFromNoteQuestions(questions);
            });
          }
        }
      });
    }

    final quiz = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final q = quiz.currentQuestion;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: quiz.isFinished
              ? _FinishedView(
                  total: quiz.total,
                  correct: quiz.correctCount,
                  onRestart: notifier.restart,
                )
              : (q == null
                  ? const EmptyState(
                      title: 'Quiz yok',
                      message: 'Henüz soru bulunamadı.',
                      icon: Icons.psychology_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soru ${quiz.currentIndex + 1}/${quiz.total}',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(q.question, style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: ListView(
                            children: [
                              ...List.generate(q.options.length, (i) {
                                final isSelected = quiz.selectedIndex == i;
                                final isCorrect = i == q.correctIndex;
                                final showResult = quiz.selectedIndex != null;
                                Color? border;
                                if (showResult && isCorrect) border = AppColors.success;
                                if (showResult && isSelected && !isCorrect) border = AppColors.error;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: BaseCard(
                                    onTap: () => notifier.selectAnswer(i),
                                    borderColor: border,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            q.options[i],
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (showResult && isCorrect)
                                          const Icon(Icons.check, color: AppColors.success),
                                        if (showResult && isSelected && !isCorrect)
                                          const Icon(Icons.close, color: AppColors.error),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (quiz.selectedIndex != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                BaseCard(
                                  child: Text(
                                    q.explanation,
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ],
                          ),
                        ),
                        PrimaryButton(
                          label: (quiz.currentIndex == quiz.total - 1) ? 'Bitir' : 'Devam',
                          onPressed: quiz.selectedIndex == null ? null : notifier.next,
                        ),
                      ],
                    )),
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.total,
    required this.correct,
    required this.onRestart,
  });

  final int total;
  final int correct;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sonuç', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        BaseCard(
          child: Text(
            'Skor: $correct / $total',
            style: AppTypography.titleMedium,
          ),
        ),
        const Spacer(),
        PrimaryButton(label: 'Tekrar başla', onPressed: onRestart),
      ],
    );
  }
}
