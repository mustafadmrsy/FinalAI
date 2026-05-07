import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/ui/app_assets.dart';
import '../../../core/services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════
//  LEVEL UP POPUP — Pixel game art + mascot animation
// ═══════════════════════════════════════════════════════════════

class LevelUpPopup extends StatefulWidget {
  const LevelUpPopup({super.key, required this.newLevel});
  final int newLevel;

  static Future<void> show(BuildContext context, {required int newLevel}) {
    Haptic.heavy();
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: LevelUpPopup(newLevel: newLevel),
      ),
    );
  }

  @override
  State<LevelUpPopup> createState() => _LevelUpPopupState();
}

class _LevelUpPopupState extends State<LevelUpPopup> with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final level = widget.newLevel;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PxDecor.gold, width: 3),
          boxShadow: [
            BoxShadow(color: PxDecor.goldDark.withAlpha(100), offset: const Offset(0, 6), blurRadius: 0),
            BoxShadow(color: PxDecor.gold.withAlpha(40), blurRadius: 30, spreadRadius: 5),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Header with gold gradient ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Column(children: [
              // Animated star burst
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _shimmerCtrl.value * 6.283,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withAlpha(60), size: 80),
                ),
              ),
            ]),
          ),

          // ── Mascot + Level info ──
          Transform.translate(
            offset: const Offset(0, -30),
            child: Column(children: [
              // Mascot animation
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: px.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: PxDecor.gold, width: 3),
                  boxShadow: [
                    BoxShadow(color: PxDecor.goldDark.withAlpha(60), offset: const Offset(0, 4), blurRadius: 0),
                  ],
                ),
                child: ClipOval(
                  child: Lottie.asset(
                    AppAssets.mascotCuteCupReading,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: PxDecor.gold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PxDecor.goldDark, width: 2),
                  boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 3), blurRadius: 0)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  Text('Seviye $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                ]),
              ),
              const SizedBox(height: 12),

              // Title
              Text('Seviye Atladin!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Tebrikler! Seviye $level\'e ulastin. Harika gidiyorsun, devam et!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textSub, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),

          // ── Stats row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _miniStat(px, Icons.star_rounded, PxDecor.gold, 'Seviye', '$level')),
              const SizedBox(width: 8),
              Expanded(child: _miniStat(px, PxIcons.xpIcon, PxIcons.xpColor, 'Sonraki', '${level * 500} XP')),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Close button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: () { Haptic.medium(); Navigator.of(context).pop(); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: PxDecor.gold,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PxDecor.goldDark, width: 2),
                  boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 4), blurRadius: 0)],
                ),
                child: const Center(child: Text('Harika!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(Px px, IconData icon, Color color, String label, String value) {
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
