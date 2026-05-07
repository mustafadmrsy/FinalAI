import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/user_stats_model.dart';

// ═══════════════════════════════════════════════════════════════
//  XP / LEVEL POPUP — Pixel game art style
// ═══════════════════════════════════════════════════════════════

class XpLevelPopup extends StatefulWidget {
  const XpLevelPopup({super.key, required this.stats});
  final UserStatsModel stats;

  static Future<void> show(BuildContext context, UserStatsModel stats) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: XpLevelPopup(stats: stats),
      ),
    );
  }

  @override
  State<XpLevelPopup> createState() => _XpLevelPopupState();
}

class _XpLevelPopupState extends State<XpLevelPopup> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final s = widget.stats;
    final xp = s.xpTotal;
    final level = (xp / 500).floor() + 1;
    final xpInLevel = xp % 500;
    final pct = (xpInLevel / 500).clamp(0.0, 1.0);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PxDecor.green, width: 3),
          boxShadow: [
            BoxShadow(color: PxDecor.greenDark.withAlpha(80), offset: const Offset(0, 6), blurRadius: 0),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Pixel game header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: PxDecor.green,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              boxShadow: [BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Column(children: [
              // Pixel shield badge
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: PxDecor.greenDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
                ),
                child: Stack(children: [
                  // Shine effect
                  Positioned(top: 4, left: 4, child: Container(
                    width: 16, height: 8,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                  )),
                  Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
                    Text('$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, height: 1)),
                  ])),
                ]),
              ),
              const SizedBox(height: 8),
              Text('Seviye $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Chunky XP progress bar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: px.cardDeco(depth: 3),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Icon(PxIcons.xpIcon, color: PxIcons.xpColor, size: 16),
                      const SizedBox(width: 4),
                      Text('$xpInLevel / 500 XP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: px.text)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: PxDecor.green, borderRadius: BorderRadius.circular(6)),
                      child: Text('Seviye ${level + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: px.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: px.border, width: 2),
                      boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 2), blurRadius: 0)],
                    ),
                    child: LayoutBuilder(builder: (_, c) => Stack(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: c.maxWidth * pct,
                        decoration: BoxDecoration(
                          color: PxDecor.green,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 2), blurRadius: 0)],
                        ),
                      ),
                      // Shine stripe on bar
                      if (pct > 0.1)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: c.maxWidth * pct,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(colors: [Colors.white.withAlpha(0), Colors.white.withAlpha(60), Colors.white.withAlpha(0)]),
                          ),
                        ),
                    ])),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Game stat tiles
              Row(children: [
                Expanded(child: _gameTile(px, Icons.auto_awesome_rounded, PxIcons.xpColor, 'Toplam', '$xp')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(px, Icons.today_rounded, PxDecor.green, 'Bugun', '${s.xpToday}')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(px, PxIcons.energyIcon, PxIcons.energyColor, 'Enerji', '${s.energy}')),
              ]),
              const SizedBox(height: 14),

              // Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: PxDecor.green,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PxDecor.greenDark, width: 2),
                    boxShadow: [BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 4), blurRadius: 0)],
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

  Widget _gameTile(Px px, IconData icon, Color color, String label, String value) {
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: Colors.white.withAlpha(200))),
      ]),
    );
  }
}
