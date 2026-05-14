import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/zigzag_path_list.dart';
import '../widgets/duo_circle_node.dart';
import '../providers/learning_path_providers.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../stats/widgets/xp_level_popup.dart';
import '../../stats/widgets/hero_xp_card.dart';
import '../widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../shop/widgets/quota_popup.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitIndex});

  final int unitIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final lessonsAsync = ref.watch(learningLessonsByUnitProvider(unitIndex));
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () { Haptic.light(); Navigator.of(context).maybePop(); },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: px.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: px.border, width: 2),
                    boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: px.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Unite $unitIndex', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
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
              child: lessonsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Hata: $err', style: TextStyle(color: px.text))),
                data: (lessons) {
                  if (lessons.isEmpty) {
                    return Center(child: Text('Ders bulunamadi', style: TextStyle(color: px.textSub, fontSize: 14)));
                  }

                  return ZigzagPathList(
                    itemCount: lessons.length,
                    itemBuilder: (context, i, isLeft) {
                      final lesson = lessons[i];
                      return DuoCircleNode(
                        label: lesson.title,
                        progress: lesson.progress,
                        isLocked: lesson.isLocked,
                        onTap: () async {
                          final stats = ref.read(userStatsProvider).valueOrNull;
                          if (stats != null && stats.energy < 3 && !stats.isPremium) {
                            final rewarded = await QuotaPopup.show(context, ref, type: QuotaType.energy);
                            ref.invalidate(userStatsProvider);
                            if (!rewarded || !context.mounted) return;
                          }
                          if (context.mounted) context.push('/path/unit/$unitIndex/lesson/${lesson.lessonIndex}');
                        },
                        accent: PxDecor.teal,
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

}
