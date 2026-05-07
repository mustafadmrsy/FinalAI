import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_assets.dart';
import '../../../core/ui/widgets/app_svg_icon.dart';
import '../providers/note_detail_provider.dart';

class QuizTab extends ConsumerWidget {
  const QuizTab({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteDetailProvider(noteId));

    return note.when(
      loading: () => const LoadingIndicator(message: 'Sorular yükleniyor...'),
      error: (e, _) => EmptyState(
        title: 'Quiz yüklenemedi',
        message: e.toString(),
        icon: Icons.error_outline,
      ),
      data: (data) {
        final questions = (data['questions'] as List?)?.cast<dynamic>() ?? [];

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            BaseCard(
              child: Row(
                children: [
                  const AppSvgIcon(AppAssets.navQuiz, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Toplam soru: ${questions.length}',
                      style: AppTypography.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Quiz başlat',
              onPressed: questions.isEmpty ? null : () => context.go('/quiz/$noteId'),
            ),
          ],
        );
      },
    );
  }
}
