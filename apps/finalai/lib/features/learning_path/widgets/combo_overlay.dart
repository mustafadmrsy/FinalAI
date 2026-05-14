import 'dart:math';
import 'package:flutter/material.dart';

import '../widgets/tasks/task_helpers.dart';

/// Non-blocking combo animation overlay — 2D pixel art style
/// Shows at 3x streak, awards energy, doesn't block user interaction
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
    Future.delayed(Duration(milliseconds: compact ? 2000 : 3000), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  State<ComboOverlay> createState() => _ComboOverlayState();
}

class _ComboOverlayState extends State<ComboOverlay> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _slideY;
  late Animation<double> _shake;
  final _rng = Random();
  late List<_PixelParticle> _particles;

  @override
  void initState() {
    super.initState();
    final dur = widget.compact ? 1800 : 2800;
    _mainCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: dur));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_mainCtrl);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_mainCtrl);
    _slideY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 40.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0), weight: 30),
    ]).animate(_mainCtrl);

    // Shake effect on impact
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -5.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    // Pixel particles
    _particleCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: dur));
    _particles = List.generate(widget.compact ? 6 : 12, (_) => _PixelParticle(
      dx: (_rng.nextDouble() - 0.5) * 200,
      dy: -_rng.nextDouble() * 160 - 40,
      size: (_rng.nextDouble() * 6 + 4).roundToDouble(),
      color: [PxDecor.orange, PxDecor.gold, PxDecor.red, Colors.white][_rng.nextInt(4)],
      delay: _rng.nextDouble() * 0.3,
    ));

    _mainCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _shakeCtrl.forward();
    });
    _particleCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _shakeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _shakeCtrl, _particleCtrl]),
      builder: (context, _) {
        if (widget.compact) return _buildCompact(context);
        return _buildFull(context);
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    final isGold = widget.streak >= 5;
    final mainColor = isGold ? PxDecor.gold : PxDecor.orange;
    final darkColor = isGold ? PxDecor.goldDark : PxDecor.orangeDark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0, right: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(_shake.value, _slideY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: darkColor, width: 3),
                    boxShadow: [
                      BoxShadow(color: darkColor, offset: const Offset(0, 4), blurRadius: 0),
                      BoxShadow(color: mainColor.withAlpha(60), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    // Pixel fire
                    _pixelFire(28, mainColor),
                    const SizedBox(width: 8),
                    Text('${widget.streak}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2))])),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                      ),
                      child: Text('+${widget.energyAwarded}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ]),
                ),
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
    final progress = _particleCtrl.value;

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: _opacity.value,
          child: Stack(alignment: Alignment.center, children: [
            // Pixel particles
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
              final ease = Curves.easeOut.transform(t);
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + p.dx * ease - p.size / 2,
                top: MediaQuery.of(context).size.height / 2 + p.dy * ease - p.size / 2,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: t * 2,
                    child: Container(
                      width: p.size, height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.white.withAlpha(120), width: 1),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Main combo badge
            Transform.translate(
              offset: Offset(_shake.value, _slideY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Pixel art fire shield
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: darkColor, width: 4),
                      boxShadow: [
                        BoxShadow(color: darkColor, offset: const Offset(0, 6), blurRadius: 0),
                        BoxShadow(color: mainColor.withAlpha(80), blurRadius: 24, spreadRadius: 8),
                      ],
                    ),
                    child: Stack(children: [
                      // Pixel shine
                      Positioned(top: 6, left: 6, child: Container(
                        width: 18, height: 10,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                      )),
                      Center(child: _pixelFire(48, mainColor)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  // Combo text banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: darkColor, width: 3),
                      boxShadow: [
                        BoxShadow(color: darkColor, offset: const Offset(0, 5), blurRadius: 0),
                      ],
                    ),
                    child: Column(children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        // Pixel star decorators
                        _pixelStar(10, Colors.white.withAlpha(200)),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.streak}x KOMBO!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 2,
                            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 0)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pixelStar(10, Colors.white.withAlpha(200)),
                      ]),
                      const SizedBox(height: 8),
                      // Energy reward badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt_rounded, color: Colors.white.withAlpha(240), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.energyAwarded} Enerji',
                            style: TextStyle(color: Colors.white.withAlpha(240), fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Pixel art fire icon built from stacked colored blocks
  Widget _pixelFire(double size, Color base) {
    final s = size / 6;
    return SizedBox(
      width: size, height: size,
      child: Stack(children: [
        // Outer flame (red/orange)
        Positioned(left: s * 1.5, top: 0, child: _px(s * 3, s * 1.5, PxDecor.red)),
        Positioned(left: s, top: s, child: _px(s * 4, s * 2, PxDecor.orange)),
        // Inner flame (yellow/gold)
        Positioned(left: s * 1.5, top: s * 1.5, child: _px(s * 3, s * 2, PxDecor.gold)),
        Positioned(left: s * 2, top: s * 0.5, child: _px(s * 2, s * 2, const Color(0xFFFFE066))),
        // Core (white hot)
        Positioned(left: s * 2.5, top: s * 2.5, child: _px(s * 1.5, s * 2, Colors.white.withAlpha(200))),
        // Base glow
        Positioned(left: s * 0.5, top: s * 3.5, child: _px(s * 5, s * 2, base.withAlpha(120))),
        Positioned(left: s, top: s * 4, child: _px(s * 4, s * 1.5, base.withAlpha(60))),
      ]),
    );
  }

  /// Single pixel block
  Widget _px(double w, double h, Color c) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  /// Pixel star decorator
  Widget _pixelStar(double size, Color color) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _PixelStarPainter(color: color)),
    );
  }
}

class _PixelParticle {
  final double dx, dy, size, delay;
  final Color color;
  const _PixelParticle({required this.dx, required this.dy, required this.size, required this.color, required this.delay});
}

class _PixelStarPainter extends CustomPainter {
  final Color color;
  _PixelStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final s = size.width / 5;
    // Cross pattern = pixel star
    canvas.drawRect(Rect.fromLTWH(s * 2, 0, s, size.height), p);
    canvas.drawRect(Rect.fromLTWH(0, s * 2, size.width, s), p);
    // Corner pixels
    canvas.drawRect(Rect.fromLTWH(s, s, s, s), p);
    canvas.drawRect(Rect.fromLTWH(s * 3, s, s, s), p);
    canvas.drawRect(Rect.fromLTWH(s, s * 3, s, s), p);
    canvas.drawRect(Rect.fromLTWH(s * 3, s * 3, s, s), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
