import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistik')),
      body: stats.when(
        loading: () => const LoadingIndicator(message: 'İstatistik yükleniyor...'),
        error: (e, _) => EmptyState(
          title: 'İstatistik yüklenemedi',
          message: e.toString(),
          icon: Icons.error_outline,
        ),
        data: (data) {
          final streak = (data['study_streak'] as int?) ?? 0;
          final answered = (data['total_questions_answered'] as int?) ?? 0;
          final correct = (data['correct_answers'] as int?) ?? 0;
          final accuracy = answered == 0 ? 0 : ((correct / answered) * 100).round();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              BaseCard(
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_outlined, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text('Streak: $streak gün', style: AppTypography.titleMedium)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BaseCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Başarı: %$accuracy  ($correct/$answered)',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
