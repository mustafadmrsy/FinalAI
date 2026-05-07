import 'dart:math';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'tasks/task_helpers.dart';

/// Full-screen celebration overlay shown when a unit is completed.
/// Shows the bike-riding mascot, animated clouds, and a funny congratulation message.
class UnitCompleteOverlay {
  UnitCompleteOverlay._();

  static const _messages = [
    'Unite bitti! Artik bu konunun patronusun!',
    'Helal olsun! Beyindeki noronlar alkisladi!',
    'Muthis! Sen mi dehasin, deha mi sen?',
    'Harika is! Maskotumuz bile sasirdi!',
    'Tebrikler! Bu unite sana cok kolay geldi!',
    'Bravo! Bir sonraki unitede gorusuruz!',
    'Vay canina! Bu hizla profesorluk yakin!',
    'Iste boyle! Bilgi makinesi gibisin!',
    'Cok iyisin! Maskotumuz seninle gurur duyuyor!',
    'Efsane! Bu uniteyi fethettin!',
  ];

  static Future<void> show(BuildContext context) async {
    final rng = Random();
    final msg = _messages[rng.nextInt(_messages.length)];

    final overlay = OverlayEntry(builder: (_) => _CelebrationWidget(message: msg));
    Overlay.of(context).insert(overlay);

    await Future.delayed(const Duration(milliseconds: 3200));
    overlay.remove();
  }
}

class _CelebrationWidget extends StatefulWidget {
  const _CelebrationWidget({required this.message});
  final String message;

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _cloudCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.elasticOut));

    _cloudCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    // Fade out before removal
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _fadeCtrl.reverse();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cloudCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Stack(children: [
            // Animated clouds
            ..._buildClouds(),
            // Center content
            Center(child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Mascot
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: PxDecor.gold.withAlpha(60), blurRadius: 30, spreadRadius: 5),
                      BoxShadow(color: PxDecor.goldDark.withAlpha(40), offset: const Offset(0, 6), blurRadius: 0),
                    ],
                    border: Border.all(color: PxDecor.gold, width: 4),
                  ),
                  child: ClipOval(
                    child: Lottie.asset(
                      'assets/mascot/Cute Cup Riding Bike.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Stars
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, color: PxDecor.gold.withAlpha(120), size: 28),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: PxDecor.gold, size: 36),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: PxDecor.gold.withAlpha(120), size: 28),
                ]),
                const SizedBox(height: 16),
                // Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: PxDecor.gold,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 4), blurRadius: 0)],
                  ),
                  child: const Text('UNITE TAMAMLANDI!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                ),
                const SizedBox(height: 14),
                // Funny message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey[700], height: 1.4),
                  ),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  List<Widget> _buildClouds() {
    const clouds = [
      (top: 40.0, right: -60.0, size: 100.0, speed: 0.3),
      (top: 100.0, right: -140.0, size: 80.0, speed: 0.5),
      (top: 200.0, right: -80.0, size: 120.0, speed: 0.2),
      (top: 320.0, right: -100.0, size: 90.0, speed: 0.4),
      (top: 450.0, right: -50.0, size: 70.0, speed: 0.6),
    ];

    return clouds.map((c) {
      return AnimatedBuilder(
        animation: _cloudCtrl,
        builder: (ctx, child) {
          final screenW = MediaQuery.of(ctx).size.width;
          final offset = (_cloudCtrl.value * c.speed * screenW * 2) % (screenW + c.size * 2) - c.size;
          return Positioned(
            top: c.top,
            right: offset,
            child: _cloudShape(c.size),
          );
        },
      );
    }).toList();
  }

  Widget _cloudShape(double size) {
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: CustomPaint(painter: _CloudPainter(size: size)),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.size});
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()..color = Colors.grey.withAlpha(25);
    final w = canvasSize.width;
    final h = canvasSize.height;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.6), width: w * 0.5, height: h * 0.8), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.4), width: w * 0.6, height: h * 0.9), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.7, h * 0.55), width: w * 0.5, height: h * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
