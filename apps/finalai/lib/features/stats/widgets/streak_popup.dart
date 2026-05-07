import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/user_stats_model.dart';

// ═══════════════════════════════════════════════════════════════
//  STREAK POPUP — Seri detay + alev animasyonu
// ═══════════════════════════════════════════════════════════════

class StreakPopup extends StatefulWidget {
  const StreakPopup({super.key, required this.stats});
  final UserStatsModel stats;

  static Future<void> show(BuildContext context, UserStatsModel stats) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: StreakPopup(stats: stats),
      ),
    );
  }

  @override
  State<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends State<StreakPopup> with TickerProviderStateMixin {
  late AnimationController _flameCtrl;
  late Animation<double> _flameScale;
  late AnimationController _enterCtrl;
  late Animation<double> _enterScale;

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _flameScale = Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _enterScale = CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut);
    _enterCtrl.forward();
  }

  @override
  void dispose() { _flameCtrl.dispose(); _enterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final s = widget.stats;
    final streak = s.studyStreak ?? 0;
    final longest = s.longestStreak ?? 0;
    final hasFreezeAvail = s.streakFreezeAvailable;
    final today = DateTime.now();

    return ScaleTransition(
      scale: _enterScale,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PxDecor.orange, width: 3),
          boxShadow: [BoxShadow(color: PxDecor.orangeDark.withAlpha(80), offset: const Offset(0, 6), blurRadius: 0)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Pixel game header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: PxDecor.orange,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              boxShadow: [BoxShadow(color: PxDecor.orangeDark, offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Column(children: [
              AnimatedBuilder(
                animation: _flameCtrl,
                builder: (_, __) => Transform.scale(
                  scale: _flameScale.value,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: PxDecor.orangeDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0),
                        BoxShadow(color: PxDecor.gold.withAlpha((100 * _flameScale.value).round()), blurRadius: 14, spreadRadius: 2),
                      ],
                    ),
                    child: Stack(children: [
                      Positioned(top: 4, left: 4, child: Container(
                        width: 16, height: 8,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                      )),
                      const Center(child: Icon(PxIcons.streakIcon, color: Colors.white, size: 36)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('$streak gun', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              const SizedBox(height: 2),
              Text('Calisma Serisi', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Son 7 gun — game style day circles
              Container(
                padding: const EdgeInsets.all(10),
                decoration: px.cardDeco(depth: 3),
                child: Column(children: [
                  Text('Son 7 Gun', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: px.textSub)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (i) {
                    final day = today.subtract(Duration(days: 6 - i));
                    final isActive = (6 - i) < streak;
                    final isToday = i == 6;
                    final dayNames = ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
                    final dayName = dayNames[day.weekday - 1];
                    return Column(children: [
                      Text(dayName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: px.textMuted)),
                      const SizedBox(height: 4),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? PxDecor.orange : (isToday ? PxDecor.orange.withAlpha(40) : px.surface),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? PxDecor.orangeDark : (isToday ? PxDecor.orange : px.border),
                            width: 2,
                          ),
                          boxShadow: isActive ? [BoxShadow(color: PxDecor.orangeDark, offset: const Offset(0, 2), blurRadius: 0)] : [],
                        ),
                        child: Center(child: isActive
                            ? const Icon(PxIcons.streakIcon, color: Colors.white, size: 14)
                            : Text('${day.day}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: px.textMuted)),
                        ),
                      ),
                    ]);
                  })),
                ]),
              ),
              const SizedBox(height: 12),

              // Game stat tiles
              Row(children: [
                Expanded(child: _gameTile(PxDecor.orange, Icons.local_fire_department_rounded, 'Mevcut', '$streak')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(PxDecor.gold, Icons.emoji_events_rounded, 'En Uzun', '$longest')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(
                  hasFreezeAvail ? PxDecor.blue : PxDecor.red,
                  hasFreezeAvail ? Icons.ac_unit_rounded : Icons.close_rounded,
                  'Freeze', hasFreezeAvail ? 'Var' : 'Yok',
                )),
              ]),
              const SizedBox(height: 14),

              // Close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: PxDecor.orange,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PxDecor.orangeDark, width: 2),
                    boxShadow: [BoxShadow(color: PxDecor.orangeDark, offset: const Offset(0, 4), blurRadius: 0)],
                  ),
                  child: const Center(child: Text('Devam Et!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _gameTile(Color color, IconData icon, String label, String value) {
    final dark = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1)).toColor();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark, width: 2),
        boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: Colors.white.withAlpha(200))),
      ]),
    );
  }
}
