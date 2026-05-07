import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../providers/user_stats_provider.dart';

// ═══════════════════════════════════════════════════════════════
//  ACHIEVEMENTS SCREEN — Pixel Art 2D
// ═══════════════════════════════════════════════════════════════

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: px.text))),
          data: (stats) {
            if (stats == null) return Center(child: Text('Istatistikler yuklenemedi', style: TextStyle(color: px.text)));

            final achievements = _buildAchievementList(stats);
            final doneCount = achievements.where((a) => a.done).length;

            return Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: px.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Basarimlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: PxDecor.gold, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)]),
                    child: Text('$doneCount/${achievements.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ]),
              ),

              // Grid
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Ozet kart
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: px.heroDeco(PxDecor.gold, PxDecor.goldDark),
                      child: Row(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(80), width: 2)),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Basarim Ilerlemen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                          const SizedBox(height: 4),
                          // Progress bar
                          Container(
                            height: 12,
                            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                            child: LayoutBuilder(builder: (_, c) => Stack(children: [
                              Container(
                                width: c.maxWidth * (achievements.isEmpty ? 0 : doneCount / achievements.length),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                              ),
                            ])),
                          ),
                          const SizedBox(height: 4),
                          Text('$doneCount / ${achievements.length} basarim tamamlandi', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w600, fontSize: 12)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Basarim kartlari
                    ...achievements.map((a) => _AchievementCard(px: px, achievement: a)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  static List<Achievement> _buildAchievementList(dynamic s) {
    return [
      // XP basarimlari
      Achievement('Ilk Adim', 'Ilk dersini tamamla', Icons.flag_rounded, PxDecor.green, s.xpTotal > 0, category: 'XP'),
      Achievement('XP Avcisi', '100 XP topla', PxIcons.xpIcon, PxIcons.xpColor, s.xpTotal >= 100, category: 'XP'),
      Achievement('XP Ustasi', '500 XP topla', Icons.auto_awesome_rounded, PxDecor.gold, s.xpTotal >= 500, category: 'XP'),
      Achievement('XP Efsanesi', '2000 XP topla', Icons.star_rounded, PxDecor.purple, s.xpTotal >= 2000, category: 'XP'),

      // Kombo basarimlari
      Achievement('Kombo x3', '3 arka arkaya dogru', Icons.whatshot_rounded, PxDecor.orange, s.comboBest >= 3, category: 'Kombo'),
      Achievement('Kombo x5', '5 arka arkaya dogru', Icons.whatshot_rounded, PxDecor.orange, s.comboBest >= 5, category: 'Kombo'),
      Achievement('Kombo x10', '10 arka arkaya', Icons.whatshot_rounded, PxDecor.purple, s.comboBest >= 10, category: 'Kombo'),
      Achievement('Kombo x25', '25 arka arkaya', Icons.whatshot_rounded, PxDecor.red, s.comboBest >= 25, category: 'Kombo'),

      // Seri basarimlari
      Achievement('3 Gun Seri', '3 gun ust uste gir', PxIcons.streakIcon, PxIcons.streakColor, (s.longestStreak ?? 0) >= 3, category: 'Seri'),
      Achievement('Haftalik Seri', '7 gun ust uste', PxIcons.streakIcon, PxIcons.streakColor, (s.longestStreak ?? 0) >= 7, category: 'Seri'),
      Achievement('Aylik Seri', '30 gun ust uste', PxIcons.streakIcon, PxDecor.gold, (s.longestStreak ?? 0) >= 30, category: 'Seri'),

      // Enerji basarimlari
      Achievement('Enerjik', 'Hic enerji bitmeden ders bitir', PxIcons.energyIcon, PxIcons.energyColor, s.energy > 0 && s.xpTotal > 0, category: 'Enerji'),

      // Gunluk gorev basarimlari
      Achievement('Gorev Takipcisi', '3 gun ust uste gunluk gorev tamamla', Icons.calendar_today_rounded, PxDecor.teal, s.dailyQuestStreak >= 3, category: 'Gorevler'),
      Achievement('Gorev Ustasi', '7 gun ust uste gunluk gorev', Icons.event_available_rounded, PxDecor.teal, s.dailyQuestStreak >= 7, category: 'Gorevler'),
    ];
  }
}

class Achievement {
  const Achievement(this.title, this.desc, this.icon, this.color, this.done, {this.category = ''});
  final String title, desc, category;
  final IconData icon;
  final Color color;
  final bool done;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.px, required this.achievement});
  final Px px;
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: a.done ? px.accentBg(a.color) : px.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: a.done ? a.color : px.border, width: 2),
          boxShadow: [BoxShadow(color: a.done ? a.color.withAlpha(px.isDark ? 30 : 60) : px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(children: [
          // Ikon kutucugu
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: a.done ? a.color : px.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.done ? a.color : px.border, width: 2),
              boxShadow: a.done ? [BoxShadow(color: a.color.withAlpha(40), offset: const Offset(0, 2), blurRadius: 0)] : [],
            ),
            child: Icon(a.done ? a.icon : Icons.lock_rounded, color: a.done ? Colors.white : px.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (a.category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(a.category.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: a.done ? a.color : px.textMuted, letterSpacing: 1)),
              ),
            Text(a.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: a.done ? px.text : px.textMuted)),
            const SizedBox(height: 2),
            Text(a.desc, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: a.done ? px.textSub : px.textMuted)),
          ])),
          if (a.done)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            )
          else
            Icon(Icons.lock_rounded, color: px.textMuted, size: 18),
        ]),
      ),
    );
  }
}
