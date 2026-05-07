import 'dart:math';
import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';

// ═══════════════════════════════════════════════════════════════
//  STREAK FREEZE / BROKEN OVERLAY — 2D Pixel Game Art
//  Frozen: buz kristalleri, mavi alev, pixel buz parcaciklari
//  Broken: kirilmis alev, kirmizi parcaciklar
// ═══════════════════════════════════════════════════════════════

class StreakFreezeOverlay extends StatefulWidget {
  const StreakFreezeOverlay({super.key, required this.type, required this.streakCount, this.onDismiss});
  final String type;
  final int streakCount;
  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context, {required String type, required int streakCount}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, a1, a2) => StreakFreezeOverlay(
        type: type,
        streakCount: streakCount,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<StreakFreezeOverlay> createState() => _StreakFreezeOverlayState();
}

class _StreakFreezeOverlayState extends State<StreakFreezeOverlay> with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _exitCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    if (widget.type == 'frozen') {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _exitCtrl.forward().then((_) {
            if (mounted) widget.onDismiss?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _particleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final isFrozen = widget.type == 'frozen';
    final mainColor = isFrozen ? const Color(0xFF4FC3F7) : PxDecor.red;
    final darkColor = isFrozen ? const Color(0xFF0288D1) : PxDecor.redDark;
    final bgColor = isFrozen ? const Color(0xFF0D1B2A) : const Color(0xFF2A0D0D);

    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _exitCtrl, _particleCtrl]),
      builder: (context, _) {
        final enter = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack).value;
        final exitV = _exitCtrl.value;
        final opacity = ((1 - exitV) * enter).clamp(0.0, 1.0);

        return Material(
          color: Colors.transparent,
          child: Stack(children: [
            // ── Dark overlay ──
            Positioned.fill(
              child: Opacity(opacity: opacity * 0.85, child: Container(color: bgColor)),
            ),

            // ── Pixel particles ──
            Positioned.fill(
              child: Opacity(
                opacity: opacity,
                child: CustomPaint(painter: _PixelParticlePainter(
                  progress: _particleCtrl.value,
                  color: mainColor,
                  isFrozen: isFrozen,
                )),
              ),
            ),

            // ── Center card ──
            Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: 0.6 + enter * 0.4 - exitV * 0.3,
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: px.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: mainColor, width: 3),
                      boxShadow: [
                        BoxShadow(color: darkColor, offset: const Offset(0, 6), blurRadius: 0),
                        BoxShadow(color: mainColor.withAlpha(40), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // ── Pixel art header ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                          boxShadow: [BoxShadow(color: darkColor, offset: const Offset(0, 4), blurRadius: 0)],
                        ),
                        child: Column(children: [
                          // Pixel icon container
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: darkColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withAlpha(60), width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
                            ),
                            child: Stack(children: [
                              // Pixel highlight
                              Positioned(top: 4, left: 4, child: Container(
                                width: 18, height: 8,
                                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                              )),
                              Center(child: CustomPaint(
                                size: const Size(48, 48),
                                painter: isFrozen ? _PixelSnowflakePainter() : _PixelBrokenFlamePainter(),
                              )),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isFrozen ? 'Seri Donduruldu!' : 'Seri Kirildi!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                          ),
                        ]),
                      ),

                      // ── Body ──
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          // Streak count display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: px.accentBg(mainColor),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: mainColor, width: 2),
                              boxShadow: [BoxShadow(color: mainColor.withAlpha(20), offset: const Offset(0, 3), blurRadius: 0)],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.local_fire_department_rounded, color: mainColor, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                isFrozen ? '${widget.streakCount} Gun Seri' : '0 Gun',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: mainColor),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 14),

                          // Description
                          Text(
                            isFrozen
                                ? 'Seri dondurucu kullanildi!\nSerin guvenle korundu.'
                                : 'Uygulamaya girmedigin icin\nserin sifirlandi.',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: px.textSub, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Info badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: px.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: px.border, width: 1.5),
                            ),
                            child: Text(
                              isFrozen ? 'Kalan freeze: kontrol et' : 'Yeni bir seri baslatabilirsin!',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textMuted),
                            ),
                          ),

                          if (!isFrozen) ...[
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: widget.onDismiss,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: PxDecor.red,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: PxDecor.redDark, width: 2),
                                  boxShadow: [BoxShadow(color: PxDecor.redDark, offset: const Offset(0, 4), blurRadius: 0)],
                                ),
                                child: const Center(child: Text('Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ── Pixel snowflake for frozen ──
class _PixelSnowflakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const ps = 3.5; // pixel size

    // Center
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: ps * 2, height: ps * 2), paint);
    // Arms (6 directions)
    for (int d = 0; d < 6; d++) {
      final angle = d * pi / 3;
      for (int i = 1; i <= 4; i++) {
        final x = cx + cos(angle) * i * ps * 1.8;
        final y = cy + sin(angle) * i * ps * 1.8;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: ps, height: ps), paint);
        // Branches at length 3
        if (i == 3) {
          for (final bAngle in [angle + pi / 6, angle - pi / 6]) {
            final bx = x + cos(bAngle) * ps * 2;
            final by = y + sin(bAngle) * ps * 2;
            canvas.drawRect(Rect.fromCenter(center: Offset(bx, by), width: ps, height: ps), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Pixel broken flame for broken streak ──
class _PixelBrokenFlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const ps = 3.5;
    final orange = Paint()..color = const Color(0xFFFF6B35);
    final red = Paint()..color = const Color(0xFFCC2936);
    final gray = Paint()..color = Colors.grey.shade600;

    // Broken flame shape — gray base with red cracks
    // Base
    for (final dy in [30.0, 27.0, 24.0]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, dy), width: ps * 6, height: ps), gray);
    }
    // Left flame piece
    canvas.drawRect(Rect.fromCenter(center: Offset(cx - 6, 20), width: ps * 2, height: ps * 3), orange);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx - 6, 14), width: ps, height: ps * 2), red);
    // Right flame piece (tilted)
    canvas.drawRect(Rect.fromCenter(center: Offset(cx + 6, 18), width: ps * 2, height: ps * 3), orange);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx + 8, 12), width: ps, height: ps * 2), red);
    // Crack line
    final crackPaint = Paint()..color = Colors.white.withAlpha(120)..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - 1, 14), Offset(cx + 2, 28), crackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Floating pixel particles ──
class _PixelParticlePainter extends CustomPainter {
  _PixelParticlePainter({required this.progress, required this.color, required this.isFrozen});
  final double progress;
  final Color color;
  final bool isFrozen;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(isFrozen ? 42 : 77);
    final paint = Paint();

    for (int i = 0; i < 16; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.2 + rng.nextDouble() * 0.6;
      final pSize = 2.0 + rng.nextDouble() * 4;
      final dir = isFrozen ? -1.0 : 1.0; // frozen: fall down, broken: rise up

      final y = (baseY + dir * progress * speed * size.height * 0.4) % size.height;
      final x = baseX + sin(progress * 2 * pi + i) * 15;
      final alpha = (sin(progress * 2 * pi + i * 0.7) * 0.5 + 0.5) * 100;

      paint.color = color.withAlpha(alpha.toInt());
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: pSize, height: pSize), const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelParticlePainter old) => true;
}
