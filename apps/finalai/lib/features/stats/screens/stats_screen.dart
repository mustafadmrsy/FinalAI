import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_stats_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/xp_level_popup.dart';
import '../widgets/streak_popup.dart';
import '../widgets/energy_popup.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/repositories/leaderboard_repository.dart';
import '../../../core/repositories/repository_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = const ['Genel', 'Alanim'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: stats.when(
          loading: () => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Istatistik yukleniyor...', style: TextStyle(color: px.textSub)),
          ])),
          error: (e, _) => Center(child: Text('Yuklenemedi: $e', style: TextStyle(color: px.text))),
          data: (s) {
            if (s == null) return Center(child: Text('Henuz istatistik verisi yok', style: TextStyle(color: px.textSub)));

            final streak = s.studyStreak ?? 0;
            final longestStreak = s.longestStreak ?? 0;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // Header
                Row(children: [
                  Expanded(child: Text('Istatistik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text))),
                  GestureDetector(
                    onTap: () { Haptic.light(); XpLevelPopup.show(context, s); },
                    child: _pxBadge(px, PxIcons.xpIcon, PxIcons.xpColor, '${s.xpTotal}'),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () { Haptic.light(); EnergyPopup.show(context, s); },
                    child: Builder(builder: (_) {
                      final epct = s.energyMax > 0 ? (s.energy / s.energyMax).clamp(0.0, 1.0) : 0.0;
                      return _pxBadge(px, PxIcons.energyIconByPct(epct), PxIcons.energyColorByPct(epct), '${s.energy}');
                    }),
                  ),
                ]),
                const SizedBox(height: 20),

                // Hero seri karti
                GestureDetector(
                  onTap: () { Haptic.light(); StreakPopup.show(context, s); },
                  child: _AnimatedStreakCard(px: px, streak: streak, longestStreak: longestStreak, comboBest: s.comboBest),
                ),
                const SizedBox(height: 16),

                // Stats grid — compact row
                Row(children: [
                  Expanded(child: _statTile(px, 'XP', '${s.xpTotal}', PxIcons.xpColor, PxIcons.xpDark, PxIcons.xpIcon)),
                  const SizedBox(width: 8),
                  Expanded(child: _statTile(px, 'Kombo', '${s.comboCurrent}', PxDecor.purple, PxDecor.purpleDark, Icons.whatshot_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: Builder(builder: (_) {
                    final epct = s.energyMax > 0 ? (s.energy / s.energyMax).clamp(0.0, 1.0) : 0.0;
                    return _statTile(px, 'Enerji', '${s.energy}', PxIcons.energyColorByPct(epct), PxIcons.energyDarkByPct(epct), PxIcons.energyIconByPct(epct));
                  })),
                ]),
                const SizedBox(height: 20),

                // ── Leaderboard Section ──
                _LeaderboardSection(px: px, tabCtrl: _tabCtrl, tabs: _tabs),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _pxBadge(Px px, IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: px.text))]),
    );
  }

  static Widget _statTile(Px px, String label, String value, Color color, Color dark, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: px.accentBg(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 30 : 60), offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.isDark ? color : dark)),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: px.isDark ? color : dark)),
      ]),
    );
  }
}

// ── Animasyonlu Seri Karti ──────────────────────────────
class _AnimatedStreakCard extends StatefulWidget {
  const _AnimatedStreakCard({required this.px, required this.streak, required this.longestStreak, required this.comboBest});
  final Px px;
  final int streak, longestStreak, comboBest;
  @override
  State<_AnimatedStreakCard> createState() => _AnimatedStreakCardState();
}

class _AnimatedStreakCardState extends State<_AnimatedStreakCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<Color?> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = ColorTween(begin: PxIcons.streakColor.withAlpha(80), end: PxDecor.gold.withAlpha(180)).animate(_ctrl);
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final px = widget.px;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: px.heroDeco(PxIcons.streakColor, PxIcons.streakDark),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(80), width: 2),
            boxShadow: [BoxShadow(color: _glow.value ?? Colors.transparent, blurRadius: 12, spreadRadius: 2)],
          ),
          child: Center(child: Transform.scale(scale: _scale.value, child: const Icon(PxIcons.streakIcon, color: Colors.white, size: 30))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Calisma Serisi', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 2),
          Text('${widget.streak} gun', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 8),
          Row(children: [
            _heroBadge('Max ${widget.longestStreak}'),
            const SizedBox(width: 8),
            _heroBadge('Combo: ${widget.comboBest}'),
          ]),
        ])),
      ]),
    );
  }

  static Widget _heroBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withAlpha(60), width: 1.5)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PIXEL LEADERBOARD SECTION
// ═══════════════════════════════════════════════════════════════

class _LeaderboardSection extends ConsumerWidget {
  const _LeaderboardSection({required this.px, required this.tabCtrl, required this.tabs});
  final Px px;
  final TabController tabCtrl;
  final List<String> tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kullanicinin alanini al
    final userSubjectAsync = ref.watch(userLearningSubjectProvider);
    final userSubject = userSubjectAsync.valueOrNull ?? '';
    // Determine which provider to use based on active tab
    final isSubject = tabCtrl.index == 1;
    final leaderboard = isSubject
        ? ref.watch(subjectLeaderboardProvider(userSubject))
        : ref.watch(leaderboardProvider);

    return Container(
      decoration: px.cardDeco(),
      child: Column(children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: PxDecor.gold,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(60), width: 2),
              ),
              child: const Center(child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Liderlik Tablosu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 16),
            ),
          ]),
        ),

        // ── Tab bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Container(
            decoration: BoxDecoration(
              color: px.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: px.border, width: 2),
            ),
            child: Row(children: List.generate(tabs.length, (i) {
              final selected = tabCtrl.index == i;
              return Expanded(child: GestureDetector(
                onTap: () { Haptic.light(); tabCtrl.animateTo(i); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? PxDecor.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: selected ? Colors.white : px.textSub,
                    ),
                  )),
                ),
              ));
            })),
          ),
        ),

        // ── Entries ──
        leaderboard.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('Yuklenemedi', style: TextStyle(color: px.textSub, fontWeight: FontWeight.w700))),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(30),
                child: Column(children: [
                  Icon(Icons.emoji_events_outlined, color: px.textSub.withAlpha(80), size: 48),
                  const SizedBox(height: 8),
                  Text('Henuz veri yok', style: TextStyle(color: px.textSub, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(children: [
                // Top 3 podium
                if (entries.length >= 3) _buildPodium(entries.take(3).toList()),
                if (entries.length >= 3) const SizedBox(height: 12),
                // Rest of list
                ...List.generate(
                  entries.length,
                  (i) => _buildRow(i, entries[i]),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // 2nd place
      Expanded(child: _podiumItem(top3[1], 2, PxDecor.blue, 70)),
      const SizedBox(width: 6),
      // 1st place
      Expanded(child: _podiumItem(top3[0], 1, PxDecor.gold, 90)),
      const SizedBox(width: 6),
      // 3rd place
      Expanded(child: _podiumItem(top3[2], 3, PxDecor.orange, 60)),
    ]);
  }

  Widget _podiumItem(LeaderboardEntry entry, int rank, Color color, double height) {
    final dark = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1)).toColor();
    final icons = [Icons.looks_one_rounded, Icons.looks_two_rounded, Icons.looks_3_rounded];
    return Column(children: [
      // Avatar circle
      Container(
        width: rank == 1 ? 48 : 40,
        height: rank == 1 ? 48 : 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: dark, width: 3),
          boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Center(child: Text(
          entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: rank == 1 ? 20 : 16),
        )),
      ),
      const SizedBox(height: 4),
      Text(
        entry.name.length > 8 ? '${entry.name.substring(0, 8)}.' : entry.name,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: px.text),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text('${entry.xpTotal} XP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color)),
      const SizedBox(height: 4),
      // Podium pillar
      Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: dark, width: 2),
          boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Center(child: Icon(icons[rank - 1], color: Colors.white, size: rank == 1 ? 28 : 22)),
      ),
    ]);
  }

  Widget _buildRow(int index, LeaderboardEntry entry) {
    return _ExpandableLeaderboardRow(px: px, index: index, entry: entry);
  }

  static Color _rankColor(int rank) {
    switch (rank) {
      case 1: return PxDecor.gold;
      case 2: return PxDecor.blue;
      case 3: return PxDecor.orange;
      default: return PxDecor.teal;
    }
  }
}

// ── Expandable Leaderboard Row ───────────────────────────
class _ExpandableLeaderboardRow extends StatefulWidget {
  const _ExpandableLeaderboardRow({required this.px, required this.index, required this.entry});
  final Px px;
  final int index;
  final LeaderboardEntry entry;

  @override
  State<_ExpandableLeaderboardRow> createState() => _ExpandableLeaderboardRowState();
}

class _ExpandableLeaderboardRowState extends State<_ExpandableLeaderboardRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final px = widget.px;
    final entry = widget.entry;
    final rank = widget.index + 1;

    Color? rowBg;
    if (entry.isCurrentUser) {
      rowBg = px.isDark ? PxDecor.gold.withAlpha(25) : PxDecor.gold.withAlpha(15);
    }

    return GestureDetector(
      onTap: () { Haptic.selection(); setState(() => _expanded = !_expanded); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _expanded ? (px.isDark ? px.surface : Colors.grey.shade50) : (rowBg ?? Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: entry.isCurrentUser ? Border.all(color: PxDecor.gold, width: 1.5) : _expanded ? Border.all(color: px.border, width: 1.5) : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Main row
          Row(children: [
            // Rank
            SizedBox(
              width: 28,
              child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: rank <= 3 ? PxDecor.gold : px.textSub)),
            ),
            // Avatar
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _LeaderboardSection._rankColor(rank),
                shape: BoxShape.circle,
                border: Border.all(color: px.border, width: 2),
              ),
              child: Center(child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              )),
            ),
            const SizedBox(width: 10),
            // Name + subject
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                entry.isCurrentUser ? '${entry.name} (Sen)' : entry.name,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.text),
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.subject.isNotEmpty)
                Text(entry.subject, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: px.textSub), overflow: TextOverflow.ellipsis),
            ])),
            // XP + level compact
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${entry.xpTotal} XP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: PxIcons.xpColor)),
              Text('Lv.${entry.level}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: px.textSub)),
            ]),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: px.textSub, size: 18),
            ),
          ]),
          // Expanded detail row
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8, left: 38),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: px.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: px.border, width: 1.5),
                ),
                child: Row(children: [
                  _detailChip(px, PxIcons.streakIcon, PxIcons.streakColor, '${entry.studyStreak}', 'Seri'),
                  const SizedBox(width: 10),
                  _detailChip(px, Icons.whatshot_rounded, PxDecor.purple, '${entry.comboBest}', 'Kombo'),
                  const SizedBox(width: 10),
                  _detailChip(px, Icons.check_circle_rounded, PxDecor.green, '${entry.correctAnswers}', 'Dogru'),
                  const SizedBox(width: 10),
                  _detailChip(px, PxIcons.xpIcon, PxIcons.xpColor, '${entry.xpTotal}', 'XP'),
                ]),
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ]),
      ),
    );
  }

  Widget _detailChip(Px px, IconData icon, Color color, String value, String label) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color)),
      Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: px.textSub)),
    ]));
  }
}
