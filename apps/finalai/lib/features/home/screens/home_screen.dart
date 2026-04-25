import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/quick_action_card.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/recent_notes_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Ana Sayfa', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'PDF Yükle',
                    subtitle: 'Not çıkar, quiz üret',
                    icon: Icons.upload_file,
                    onTap: () => context.go('/upload'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: QuickActionCard(
                    title: 'İstatistik',
                    subtitle: 'Streak & başarı',
                    icon: Icons.bar_chart,
                    onTap: () => context.go('/stats'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const DailyGoalCard(),
            const SizedBox(height: AppSpacing.lg),
            const RecentNotesList(),
          ],
        ),
      ),
    );
  }
}
