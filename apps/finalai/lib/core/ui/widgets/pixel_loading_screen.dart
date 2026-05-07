import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL LOADING SCREEN — Clean splash like Duolingo
//  Teal gradient background + centered logo with gentle animation
// ═══════════════════════════════════════════════════════════════

class PixelLoadingScreen extends StatefulWidget {
  const PixelLoadingScreen({super.key, this.message});
  final String? message;

  @override
  State<PixelLoadingScreen> createState() => _PixelLoadingScreenState();
}

class _PixelLoadingScreenState extends State<PixelLoadingScreen> with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10C7C0),
              Color(0xFF0BB6B0),
              Color(0xFF0AA7A2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_enterCtrl, _pulseCtrl]),
              builder: (_, __) {
                final enter = CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut).value;
                final pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut).value;
                final scale = 0.92 + pulse * 0.08;
                final yOff = pulse * -6.0;
                final shadowAlpha = (30 + pulse * 40).toInt();

                return Transform.translate(
                  offset: Offset(0, yOff),
                  child: Transform.scale(
                    scale: enter * scale,
                    child: Opacity(
                      opacity: enter.clamp(0.0, 1.0),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(shadowAlpha),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
