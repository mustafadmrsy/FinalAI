import 'package:flutter/material.dart';

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: CustomPaint(
        painter: _BottomWavesPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFFFFFFF).withAlpha((0.12 * 255).round());
    final paint2 = Paint()..color = const Color(0xFFFFFFFF).withAlpha((0.18 * 255).round());

    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 110)
      ..quadraticBezierTo(size.width * 0.25, size.height - 150, size.width * 0.55, size.height - 120)
      ..quadraticBezierTo(size.width * 0.78, size.height - 95, size.width, size.height - 135)
      ..lineTo(size.width, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 70)
      ..quadraticBezierTo(size.width * 0.22, size.height - 105, size.width * 0.52, size.height - 78)
      ..quadraticBezierTo(size.width * 0.8, size.height - 52, size.width, size.height - 82)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
