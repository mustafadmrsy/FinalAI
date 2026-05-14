import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/learning_path_providers.dart';
import '../widgets/zigzag_path_list.dart';
import '../widgets/duo_circle_node.dart';
import '../widgets/tasks/task_helpers.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../stats/widgets/xp_level_popup.dart';
import '../../stats/widgets/hero_xp_card.dart';
import '../../../core/services/haptic_service.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final units = ref.watch(learningUnitsProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: units.when(
          loading: () => const Center(child: LoadingIndicator(message: 'Uniteler hazirlaniyor...')),
          error: (e, _) => Center(
            child: EmptyState(
              title: 'Uniteler yuklenemedi',
              message: e.toString(),
              icon: Icons.error_outline,
            ),
          ),
          data: (list) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text('Egitim Yolun', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text))),
                  statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (s) => s == null ? const SizedBox.shrink() : GreenXpBadge(
                      stats: s,
                      onTap: () { Haptic.light(); XpLevelPopup.show(context, s); },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: ZigzagPathList(
                    itemCount: list.length,
                    itemBuilder: (context, i, isLeft) {
                      final u = list[i];
                      return DuoCircleNode(
                        label: u.title,
                        progress: u.progress,
                        isLocked: u.isLocked,
                        onTap: () => context.push('/path/unit/${u.index}'),
                      );
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
