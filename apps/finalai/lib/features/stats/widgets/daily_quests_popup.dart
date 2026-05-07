import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/user_stats_model.dart';

// ═══════════════════════════════════════════════════════════════
//  DAILY QUESTS POPUP — 2D Pixel Game Art Style
//  Game card header, pixel progress bars, quest milestones
// ═══════════════════════════════════════════════════════════════

class DailyQuestsPopup extends StatelessWidget {
  const DailyQuestsPopup({super.key, required this.stats});
  final UserStatsModel stats;

  static Future<void> show(BuildContext context, UserStatsModel stats) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: DailyQuestsPopup(stats: stats),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    final quests = [
      _QuestItem('Ders Tamamla', '${stats.dailyQuestLessonsGoal} ders bitir', Icons.menu_book_rounded, PxDecor.green, PxDecor.greenDark, stats.dailyQuestLessons, stats.dailyQuestLessonsGoal),
      _QuestItem('XP Topla', '${stats.dailyQuestXpGoal} XP kazan', PxIcons.xpIcon, PxDecor.blue, PxDecor.blueDark, stats.dailyQuestXp, stats.dailyQuestXpGoal),
      _QuestItem('Dogru Cevapla', '${stats.dailyQuestCorrectGoal} dogru cevap', Icons.check_circle_rounded, PxDecor.teal, PxDecor.tealDark, stats.dailyQuestCorrect, stats.dailyQuestCorrectGoal),
    ];

    final allDone = quests.every((q) => q.current >= q.goal);
    final doneCount = quests.where((q) => q.current >= q.goal).length;
    final headerColor = allDone ? PxDecor.gold : PxDecor.teal;
    final headerDark = allDone ? PxDecor.goldDark : PxDecor.tealDark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: headerColor, width: 3),
        boxShadow: [
          BoxShadow(color: headerDark, offset: const Offset(0, 6), blurRadius: 0),
          BoxShadow(color: headerColor.withAlpha(30), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Pixel game header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            boxShadow: [BoxShadow(color: headerDark, offset: const Offset(0, 4), blurRadius: 0)],
          ),
          child: Column(children: [
            // Pixel icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: headerDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(60), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Stack(children: [
                Positioned(top: 4, left: 4, child: Container(
                  width: 14, height: 6,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(3)),
                )),
                Center(child: Icon(allDone ? Icons.celebration_rounded : Icons.flag_rounded, color: Colors.white, size: 30)),
              ]),
            ),
            const SizedBox(height: 10),
            Text(allDone ? 'Hepsi Tamam!' : 'Gunluk Gorevler', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            // Progress chips
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text('$doneCount/${quests.length} tamamlandi', style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              if (stats.dailyQuestStreak > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.white.withAlpha(220), size: 13),
                    const SizedBox(width: 3),
                    Text('${stats.dailyQuestStreak} gun', style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w800, fontSize: 12)),
                  ]),
                ),
              ],
            ]),
          ]),
        ),

        // ── Quest cards ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(children: [
            for (int i = 0; i < quests.length; i++) ...[
              _buildQuestCard(px, quests[i]),
              if (i < quests.length - 1) const SizedBox(height: 10),
            ],
          ]),
        ),

        // ── Reward section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: allDone ? px.accentBg(PxDecor.gold) : px.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: allDone ? PxDecor.gold : px.border, width: 2),
              boxShadow: [BoxShadow(color: (allDone ? PxDecor.goldDark : px.shadow).withAlpha(allDone ? 40 : 255), offset: const Offset(0, 2), blurRadius: 0)],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: allDone ? PxDecor.gold : px.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: allDone ? PxDecor.gold : px.border, width: 2),
                ),
                child: Icon(Icons.emoji_events_rounded, color: allDone ? Colors.white : px.textMuted, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(allDone ? 'Tum gorevler tamamlandi!' : 'Tum gorevleri tamamla', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: allDone ? PxDecor.gold : px.text)),
                Text(allDone ? 'Bonus XP kazandin!' : 'Bonus XP kazan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: allDone ? PxDecor.gold.withAlpha(180) : px.textMuted)),
              ])),
              if (allDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: PxDecor.gold, borderRadius: BorderRadius.circular(8)),
                  child: const Text('+25 XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
            ]),
          ),
        ),

        // ── Close button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: allDone ? PxDecor.gold : headerColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: allDone ? PxDecor.goldDark : headerDark, width: 2),
                boxShadow: [BoxShadow(color: allDone ? PxDecor.goldDark : headerDark, offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Center(child: Text(
                allDone ? 'Harika!' : 'Devam Et',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              )),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuestCard(Px px, _QuestItem q) {
    final done = q.current >= q.goal;
    final pct = q.goal > 0 ? (q.current / q.goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? px.accentBg(q.color) : px.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? q.color : px.border, width: 2),
        boxShadow: [BoxShadow(color: (done ? q.dark : px.shadow).withAlpha(done ? 40 : 255), offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Row(children: [
        // Icon badge
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: done ? q.color : px.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: done ? q.color : px.border, width: 2),
            boxShadow: done ? [BoxShadow(color: q.dark, offset: const Offset(0, 2), blurRadius: 0)] : null,
          ),
          child: Stack(children: [
            if (done) Positioned(top: 3, left: 3, child: Container(
              width: 10, height: 5,
              decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(2)),
            )),
            Center(child: Icon(done ? Icons.check_rounded : q.icon, color: done ? Colors.white : q.color, size: 22)),
          ]),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(q.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: done ? q.color : px.text))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: done ? q.color : px.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: done ? q.color : px.border, width: 1.5),
              ),
              child: Text('${q.current}/${q.goal}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: done ? Colors.white : px.textSub)),
            ),
          ]),
          const SizedBox(height: 6),
          // Pixel progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: done ? q.color.withAlpha(30) : px.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: done ? q.color.withAlpha(80) : px.border, width: 1.5),
              boxShadow: [BoxShadow(color: px.shadow.withAlpha(40), offset: const Offset(0, 1), blurRadius: 0)],
            ),
            child: LayoutBuilder(builder: (_, c) => Stack(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: c.maxWidth * pct,
                decoration: BoxDecoration(
                  color: q.color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: q.dark, offset: const Offset(0, 2), blurRadius: 0)],
                ),
                child: pct > 0.15 ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(width: 4, height: 6, decoration: BoxDecoration(color: Colors.white.withAlpha(60), borderRadius: BorderRadius.circular(1))),
                  ),
                ) : null,
              ),
            ])),
          ),
          const SizedBox(height: 3),
          Text(q.desc, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: px.textMuted)),
        ])),
      ]),
    );
  }
}

class _QuestItem {
  const _QuestItem(this.title, this.desc, this.icon, this.color, this.dark, this.current, this.goal);
  final String title, desc;
  final IconData icon;
  final Color color, dark;
  final int current, goal;
}
