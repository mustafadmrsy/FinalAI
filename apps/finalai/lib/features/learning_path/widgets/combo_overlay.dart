import 'package:flutter/material.dart';

import '../widgets/tasks/task_helpers.dart';

/// Non-blocking combo animation overlay
/// Shows at 3x and 5x streaks, awards energy, doesn't block user interaction
class ComboOverlay extends StatefulWidget {
  const ComboOverlay({super.key, required this.streak, required this.energyAwarded, this.compact = false});
  final int streak;
  final int energyAwarded;
  final bool compact;

  /// Show combo overlay as a non-blocking overlay entry
  static void show(BuildContext context, {required int streak, required int energyAwarded, bool compact = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => ComboOverlay(
      streak: streak,
      energyAwarded: energyAwarded,
      compact: compact,
    ));
    overlay.insert(entry);
    // Auto-remove after animation
    Future.delayed(Duration(milliseconds: compact ? 1800 : 2500), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  State<ComboOverlay> createState() => _ComboOverlayState();
}

class _ComboOverlayState extends State<ComboOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    final duration = widget.compact ? 1600 : 2200;
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: duration));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_ctrl);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);
    _slideY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 30.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0), weight: 30),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        if (widget.compact) return _buildCompact(context);
        return _buildFull(context);
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: IgnorePointer(
        child: Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slideY.value),
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [PxDecor.gold, PxDecor.orange]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PxDecor.goldDark, width: 2),
                  boxShadow: [
                    BoxShadow(color: PxDecor.goldDark.withAlpha(80), offset: const Offset(0, 4), blurRadius: 8),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.whatshot_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text('${widget.streak}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('+${widget.energyAwarded}⚡', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final isGold = widget.streak >= 5;
    final mainColor = isGold ? PxDecor.gold : PxDecor.orange;
    final darkColor = isGold ? PxDecor.goldDark : PxDecor.orangeDark;

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: _opacity.value,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _slideY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Flame icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [mainColor, darkColor],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(180), width: 3),
                      boxShadow: [
                        BoxShadow(color: mainColor.withAlpha(120), blurRadius: 24, spreadRadius: 4),
                        BoxShadow(color: darkColor.withAlpha(80), offset: const Offset(0, 6), blurRadius: 0),
                      ],
                    ),
                    child: const Center(child: Icon(Icons.whatshot_rounded, color: Colors.white, size: 42)),
                  ),
                  const SizedBox(height: 12),
                  // Streak text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [mainColor, darkColor]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(100), width: 2),
                      boxShadow: [
                        BoxShadow(color: darkColor.withAlpha(100), offset: const Offset(0, 4), blurRadius: 0),
                      ],
                    ),
                    child: Column(children: [
                      Text(
                        '${widget.streak}x KOMBO!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${widget.energyAwarded} Enerji kazandin!',
                        style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
