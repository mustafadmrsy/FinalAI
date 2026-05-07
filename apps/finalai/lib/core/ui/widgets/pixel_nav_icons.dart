import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL NAV ICONS — Colorful 2D game art style icons for navbar
//  Each icon is drawn using Flutter shapes/containers, always colorful.
// ═══════════════════════════════════════════════════════════════

class PixelNavIcons {
  PixelNavIcons._();

  // ── Home: Pixel birdhouse style ──
  static Widget home({double size = 28, bool active = false}) {
    return SizedBox(
      width: size, height: size,
      child: Stack(children: [
        // Roof
        Positioned(
          left: 0, right: 0, top: 0,
          child: Center(child: CustomPaint(
            size: Size(size, size * 0.45),
            painter: _RoofPainter(active: active),
          )),
        ),
        // House body
        Positioned(
          left: size * 0.18, right: size * 0.18, top: size * 0.38, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFB347) : const Color(0xFFD4A574),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF8B6914), width: 1),
            ),
            child: Center(
              child: Container(
                width: size * 0.22, height: size * 0.22,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF4A3520) : const Color(0xFF5C4033),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Documents: Scroll/book style ──
  static Widget documents({double size = 28, bool active = false}) {
    return SizedBox(
      width: size, height: size,
      child: Stack(children: [
        // Back page
        Positioned(
          left: size * 0.1, top: size * 0.06, right: size * 0.04, bottom: size * 0.04,
          child: Container(
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE0A0FF) : const Color(0xFFC490D4),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF8B5AA6), width: 1),
            ),
          ),
        ),
        // Front page
        Positioned(
          left: size * 0.04, top: size * 0.12, right: size * 0.1, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF0D0FF) : const Color(0xFFDEB8EE),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF9B6AB6), width: 1),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: size * 0.4, height: 2, color: active ? const Color(0xFFAA60CC) : const Color(0xFF9B6AB6)),
              SizedBox(height: size * 0.08),
              Container(width: size * 0.3, height: 2, color: active ? const Color(0xFFAA60CC) : const Color(0xFF9B6AB6)),
            ]),
          ),
        ),
        // Quill/pen
        Positioned(
          right: 0, top: 0,
          child: Container(
            width: size * 0.22, height: size * 0.22,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFD700) : const Color(0xFFDAA520),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit, size: size * 0.13, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  // ── Path/Learn: Game map node style ──
  static Widget path({double size = 28, bool active = false}) {
    return SizedBox(
      width: size, height: size,
      child: Stack(children: [
        // Path line
        Positioned.fill(
          child: CustomPaint(painter: _PathLinePainter(active: active)),
        ),
        // Node 1 (top-left)
        Positioned(
          left: size * 0.05, top: size * 0.05,
          child: Container(
            width: size * 0.32, height: size * 0.32,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1CB0F6) : const Color(0xFF5BABDD),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0D7AB5), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF0D7AB5).withAlpha(60), offset: const Offset(0, 1.5), blurRadius: 0)],
            ),
            child: Icon(Icons.star_rounded, size: size * 0.18, color: Colors.white),
          ),
        ),
        // Node 2 (center-right)
        Positioned(
          right: size * 0.1, top: size * 0.34,
          child: Container(
            width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF58CC02) : const Color(0xFF78B842),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3A8202), width: 1.5),
            ),
            child: Icon(Icons.check_rounded, size: size * 0.16, color: Colors.white),
          ),
        ),
        // Node 3 (bottom-left)
        Positioned(
          left: size * 0.12, bottom: size * 0.02,
          child: Container(
            width: size * 0.3, height: size * 0.3,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF9600) : const Color(0xFFD4890A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB07000), width: 1.5),
            ),
            child: Icon(Icons.flag_rounded, size: size * 0.16, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  // ── Menu/Profile: Chat bubble with heart like the image ──
  static Widget menu({double size = 28, bool active = false}) {
    return SizedBox(
      width: size, height: size,
      child: Stack(children: [
        // Chat bubble
        Positioned(
          left: 0, top: 0, right: size * 0.08, bottom: size * 0.15,
          child: Container(
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF6FAE) : const Color(0xFFE88BB5),
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(color: const Color(0xFFCC4488), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFFCC4488).withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)],
            ),
            child: Center(
              child: Icon(Icons.favorite_rounded, size: size * 0.38, color: Colors.white),
            ),
          ),
        ),
        // Bubble tail
        Positioned(
          left: size * 0.15, bottom: size * 0.04,
          child: CustomPaint(
            size: Size(size * 0.18, size * 0.14),
            painter: _BubbleTailPainter(color: active ? const Color(0xFFFF6FAE) : const Color(0xFFE88BB5)),
          ),
        ),
      ]),
    );
  }
}

// ── Custom painters ──

class _RoofPainter extends CustomPainter {
  _RoofPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? const Color(0xFFFF4444) : const Color(0xFFCC3333)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xFF8B1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _RoofPainter old) => old.active != active;
}

class _PathLinePainter extends CustomPainter {
  _PathLinePainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? const Color(0xFF1CB0F6).withAlpha(120) : const Color(0xFF888888).withAlpha(80)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.width * 0.22)
      ..quadraticBezierTo(size.width * 0.7, size.width * 0.2, size.width * 0.75, size.width * 0.5)
      ..quadraticBezierTo(size.width * 0.65, size.width * 0.8, size.width * 0.28, size.width * 0.85);

    // Draw dashed
    final pathMetrics = path.computeMetrics();
    for (final pm in pathMetrics) {
      double dist = 0;
      while (dist < pm.length) {
        final end = (dist + 3).clamp(0.0, pm.length);
        canvas.drawPath(pm.extractPath(dist, end), paint);
        dist += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter old) => old.active != active;
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) => old.color != color;
}
