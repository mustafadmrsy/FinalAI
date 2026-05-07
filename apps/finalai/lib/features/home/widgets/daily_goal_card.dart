import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../stats/widgets/daily_quests_popup.dart';
import '../../../core/services/haptic_service.dart';

class DailyGoalCard extends ConsumerWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final statsAsync = ref.watch(userStatsProvider);

    return statsAsync.when(
      loading: () => _skeleton(px),
      error: (_, __) => _skeleton(px),
      data: (s) {
        if (s == null) return _skeleton(px);

        final lessons = s.dailyQuestLessons;
        final lessonsGoal = s.dailyQuestLessonsGoal;
        final correct = s.dailyQuestCorrect;
        final correctGoal = s.dailyQuestCorrectGoal;
        final xp = s.dailyQuestXp;
        final xpGoal = s.dailyQuestXpGoal;

        // Toplam ilerleme (3 gorev ortlamasi)
        final pct = ((lessons / lessonsGoal) + (correct / correctGoal) + (xp / xpGoal)) / 3.0;
        final allDone = lessons >= lessonsGoal && correct >= correctGoal && xp >= xpGoal;

        return GestureDetector(
          onTap: () { Haptic.light(); DailyQuestsPopup.show(context, s); },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: px.accentBg(allDone ? PxDecor.gold : PxDecor.green),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: allDone ? PxDecor.gold : PxDecor.green, width: 2),
              boxShadow: [BoxShadow(color: (allDone ? PxDecor.goldDark : PxDecor.greenDark).withAlpha(px.isDark ? 30 : 60), offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: allDone ? PxDecor.gold : PxDecor.green, borderRadius: BorderRadius.circular(11)),
                  child: Icon(allDone ? Icons.celebration_rounded : Icons.flag_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    allDone ? 'Gorevler tamamlandi!' : 'Gunluk Gorevler',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.isDark ? (allDone ? PxDecor.gold : PxDecor.green) : (allDone ? PxDecor.goldDark : PxDecor.greenDark)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$lessons/$lessonsGoal ders · $correct/$correctGoal dogru · $xp/$xpGoal XP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textSub),
                  ),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: allDone ? PxDecor.gold : PxDecor.green, borderRadius: BorderRadius.circular(8)),
                  child: Text('${(pct * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: (allDone ? PxDecor.gold : PxDecor.green).withAlpha(px.isDark ? 20 : 40),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: (allDone ? PxDecor.gold : PxDecor.green).withAlpha(80), width: 1.5),
                ),
                child: LayoutBuilder(builder: (_, c) => Stack(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: c.maxWidth * pct.clamp(0.0, 1.0),
                    decoration: BoxDecoration(color: allDone ? PxDecor.gold : PxDecor.green, borderRadius: BorderRadius.circular(6)),
                  ),
                ])),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _skeleton(Px px) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 90,
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: px.border, width: 2),
      ),
      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: px.textMuted))),
    );
  }
}
