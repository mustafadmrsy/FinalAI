import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/user_stats_model.dart';

// ═══════════════════════════════════════════════════════════════
//  ENERGY POPUP — Pixel game art style
// ═══════════════════════════════════════════════════════════════

class EnergyPopup extends StatefulWidget {
  const EnergyPopup({super.key, required this.stats});
  final UserStatsModel stats;

  static void show(BuildContext context, UserStatsModel stats) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: EnergyPopup(stats: stats),
      ),
    );
  }

  @override
  State<EnergyPopup> createState() => _EnergyPopupState();
}

class _EnergyPopupState extends State<EnergyPopup> with SingleTickerProviderStateMixin {
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
    final pct = s.energyMax > 0 ? (s.energy / s.energyMax).clamp(0.0, 1.0) : 0.0;

    // Dynamic theme color based on energy level
    final themeColor = PxIcons.energyColorByPct(pct);
    final themeDark = PxIcons.energyDarkByPct(pct);
    final themeIcon = PxIcons.energyIconByPct(pct);

    String statusLabel;
    if (pct > 0.6) { statusLabel = 'Enerji dolu!'; }
    else if (pct > 0.3) { statusLabel = 'Orta seviye'; }
    else { statusLabel = 'Dusuk enerji!'; }

    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor, width: 3),
          boxShadow: [BoxShadow(color: themeDark.withAlpha(80), offset: const Offset(0, 6), blurRadius: 0)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Pixel game header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              boxShadow: [BoxShadow(color: themeDark, offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: themeDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
                ),
                child: Stack(children: [
                  Positioned(top: 4, left: 4, child: Container(
                    width: 16, height: 8,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                  )),
                  Center(child: Icon(themeIcon, color: Colors.white, size: 36)),
                ]),
              ),
              const SizedBox(height: 10),
              Text('${s.energy} / ${s.energyMax}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              const SizedBox(height: 2),
              Text(statusLabel, style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Chunky energy bar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: px.cardDeco(depth: 3),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Icon(themeIcon, color: themeColor, size: 16),
                      const SizedBox(width: 4),
                      Text('${s.energy} / ${s.energyMax}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: px.text)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(6)),
                      child: Text('${(pct * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
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
                          color: themeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: themeDark, offset: const Offset(0, 2), blurRadius: 0)],
                        ),
                      ),
                    ])),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Game stat tiles
              Row(children: [
                Expanded(child: _gameTile(themeColor, themeIcon, 'Mevcut', '${s.energy}')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(PxDecor.green, Icons.battery_full_rounded, 'Maks', '${s.energyMax}')),
                const SizedBox(width: 8),
                Expanded(child: _gameTile(PxDecor.blue, Icons.refresh_rounded, 'Reset', 'Gunluk')),
              ]),
              const SizedBox(height: 12),

              // Info box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: px.accentBg(PxDecor.blue),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PxDecor.blue, width: 2),
                  boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(40), offset: const Offset(0, 2), blurRadius: 0)],
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, color: PxDecor.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Her ders 1 enerji harcar. Yanlis cevap 3 enerji kaybettirir. Enerji her gun ${s.energyMax} olarak sifirlanir.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textSub),
                  )),
                ]),
              ),
              const SizedBox(height: 14),

              // Close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: themeDark, width: 2),
                    boxShadow: [BoxShadow(color: themeDark, offset: const Offset(0, 4), blurRadius: 0)],
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
