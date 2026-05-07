import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/quick_action_card.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/recent_notes_list.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../stats/widgets/xp_level_popup.dart';
import '../../stats/widgets/streak_popup.dart';
import '../../stats/widgets/energy_popup.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // ─── TOP BAR ───
            Row(children: [
              statsAsync.when(
                loading: () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: px.cardDeco(depth: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(PxIcons.streakIcon, color: PxIcons.streakColor, size: 18),
                    const SizedBox(width: 4),
                    Text('...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
                  ]),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: px.cardDeco(depth: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(PxIcons.streakIcon, color: PxIcons.streakColor, size: 18),
                    const SizedBox(width: 4),
                    Text('0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
                  ]),
                ),
                data: (s) => GestureDetector(
                  onTap: () { Haptic.light(); if (s != null) StreakPopup.show(context, s); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: px.cardDeco(depth: 3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(PxIcons.streakIcon, color: PxIcons.streakColor, size: 18),
                      const SizedBox(width: 4),
                      Text('${s?.studyStreak ?? 0}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
                    ]),
                  ),
                ),
              ),
              const Spacer(),
              statsAsync.when(
                loading: () => const SizedBox(width: 64, height: 24, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                error: (_, __) => _pxBadge(px, PxIcons.energyIconByPct(0), PxDecor.red, '0'),
                data: (s) {
                  final pct = (s != null && s.energyMax > 0) ? (s.energy / s.energyMax).clamp(0.0, 1.0) : 0.0;
                  return GestureDetector(
                    onTap: () { Haptic.light(); if (s != null) EnergyPopup.show(context, s); },
                    child: _pxBadge(px, PxIcons.energyIconByPct(pct), PxIcons.energyColorByPct(pct), '${s?.energy ?? 0}'),
                  );
                },
              ),
              const SizedBox(width: 8),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => _pxBadge(px, PxIcons.xpIcon, PxIcons.xpColor, '0'),
                data: (s) => GestureDetector(
                  onTap: () { Haptic.light(); if (s != null) XpLevelPopup.show(context, s); },
                  child: _pxBadge(px, PxIcons.xpIcon, PxIcons.xpColor, '${s?.xpTotal ?? 0}'),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ─── Hero XP card ───
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) {
                final xp = s?.xpTotal ?? 0;
                final level = (xp / 500).floor() + 1;
                final xpInLevel = xp % 500;
                return GestureDetector(
                onTap: () { Haptic.light(); if (s != null) XpLevelPopup.show(context, s); },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: px.heroDeco(PxDecor.teal, PxDecor.tealDark),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withAlpha(80), width: 2)),
                        child: Center(child: Text('$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Seviye $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${500 - xpInLevel} XP daha kazanarak seviye atla!', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w600, fontSize: 12)),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('$xpInLevel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(child: Container(
                        height: 14,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.white.withAlpha(60), width: 1.5)),
                        child: LayoutBuilder(builder: (_, c) => Stack(children: [
                          Container(width: c.maxWidth * (xpInLevel / 500).clamp(0, 1), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        ])),
                      )),
                      const SizedBox(width: 8),
                      Text('500 XP', style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                  ]),
                ),
              );
              },
            ),
            const SizedBox(height: 16),

            // ─── Daily Goal ───
            const DailyGoalCard(),
            const SizedBox(height: 20),

            // ─── Quick Actions ───
            Text('Basla', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: QuickActionCard(title: 'PDF Yukle', subtitle: '', icon: Icons.upload_file, color: PxDecor.green, onTap: () => context.go('/upload'))),
              const SizedBox(width: 10),
              Expanded(child: QuickActionCard(title: 'Quiz Coz', subtitle: '', icon: Icons.bolt, color: PxDecor.orange, onTap: () => context.go('/quiz'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: QuickActionCard(title: 'Ogrenme Yolu', subtitle: '', icon: Icons.route_rounded, color: PxDecor.blue, onTap: () => context.go('/path'))),
              const SizedBox(width: 10),
              Expanded(child: QuickActionCard(title: 'Istatistik', subtitle: '', icon: Icons.bar_chart_rounded, color: PxDecor.teal, onTap: () => context.go('/stats'))),
            ]),
            const SizedBox(height: 20),

            // ─── Recent Notes ───
            Text('Son notlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
            const SizedBox(height: 12),
            const RecentNotesList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _pxBadge(Px px, IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: px.border, width: 2),
        boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: px.text)),
      ]),
    );
  }
}
