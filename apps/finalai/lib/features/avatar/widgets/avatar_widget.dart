import 'dart:math';
import 'package:flutter/material.dart';

import '../models/avatar_model.dart';
import '../data/avatar_parts.dart';

// ═══════════════════════════════════════════════════════════════
//  AVATAR WIDGET — 2D Duolingo-style character renderer
//  Composites face, hair, eyes, mouth, outfit, accessories
// ═══════════════════════════════════════════════════════════════

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key, required this.avatar, this.size = 120});
  final AvatarModel avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(painter: _AvatarPainter(avatar, size)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.av, this.sz);
  final AvatarModel av;
  final double sz;

  @override
  void paint(Canvas canvas, Size size) {
    final s = sz / 120; // scale factor
    final cx = size.width / 2;
    final skin = AvatarParts.skinTones[av.skinTone.clamp(0, AvatarParts.skinTones.length - 1)];
    final skinDark = HSLColor.fromColor(skin).withLightness((HSLColor.fromColor(skin).lightness - 0.08).clamp(0, 1)).toColor();
    final hairColor = AvatarParts.hairColors[av.hairColor.clamp(0, AvatarParts.hairColors.length - 1)];
    final hairDark = HSLColor.fromColor(hairColor).withLightness((HSLColor.fromColor(hairColor).lightness - 0.12).clamp(0, 1)).toColor();
    final outfitColor = AvatarParts.outfitColors[av.outfitColor.clamp(0, AvatarParts.outfitColors.length - 1)];
    final outfitDark = HSLColor.fromColor(outfitColor).withLightness((HSLColor.fromColor(outfitColor).lightness - 0.12).clamp(0, 1)).toColor();

    // ── Body / Outfit ──
    _drawOutfit(canvas, cx, s, outfitColor, outfitDark);

    // ── Neck ──
    final neckPaint = Paint()..color = skin;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, 82 * s), width: 26 * s, height: 18 * s), Radius.circular(6 * s)), neckPaint);

    // ── Head (face) ──
    _drawHead(canvas, cx, s, skin, skinDark);

    // ── Hair ──
    _drawHair(canvas, cx, s, hairColor, hairDark);

    // ── Eyes ──
    _drawEyes(canvas, cx, s);

    // ── Nose ──
    final nosePaint = Paint()..color = skinDark;
    canvas.drawCircle(Offset(cx, 56 * s), 2.5 * s, nosePaint);

    // ── Mouth ──
    _drawMouth(canvas, cx, s);

    // ── Ears ──
    final earPaint = Paint()..color = skin;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 36 * s, 48 * s), width: 12 * s, height: 16 * s), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 36 * s, 48 * s), width: 12 * s, height: 16 * s), earPaint);

    // ── Accessory ──
    _drawAccessory(canvas, cx, s, hairColor);
  }

  void _drawHead(Canvas canvas, double cx, double s, Color skin, Color skinDark) {
    final headPaint = Paint()..color = skin;
    final headShadow = Paint()..color = skinDark;
    // Shadow
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 50 * s), width: 68 * s, height: 72 * s),
      Radius.circular(30 * s),
    ), headShadow);
    // Head
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 48 * s), width: 68 * s, height: 72 * s),
      Radius.circular(30 * s),
    ), headPaint);
  }

  void _drawHair(Canvas canvas, double cx, double s, Color color, Color dark) {
    final paint = Paint()..color = color;
    final paintDark = Paint()..color = dark;
    final isFemale = av.gender == AvatarGender.female;
    final style = av.hairStyle.clamp(0, 4);

    if (!isFemale) {
      switch (style) {
        case 0: // Kisa
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 10 * s, 76 * s, 28 * s), Radius.circular(14 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 36 * s, 8 * s, 72 * s, 28 * s), Radius.circular(14 * s)), paint);
          break;
        case 1: // Dalgali
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 6 * s, 80 * s, 34 * s), Radius.circular(16 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 4 * s, 76 * s, 34 * s), Radius.circular(16 * s)), paint);
          // wave bumps
          for (int i = -1; i <= 1; i++) {
            canvas.drawCircle(Offset(cx + i * 14 * s, 8 * s), 10 * s, paint);
          }
          break;
        case 2: // Yukari (spike)
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 36 * s, 8 * s, 72 * s, 26 * s), Radius.circular(12 * s)), paint);
          for (int i = -2; i <= 2; i++) {
            final path = Path()
              ..moveTo(cx + i * 12 * s - 6 * s, 14 * s)
              ..lineTo(cx + i * 12 * s, -4 * s)
              ..lineTo(cx + i * 12 * s + 6 * s, 14 * s)
              ..close();
            canvas.drawPath(path, paint);
          }
          break;
        case 3: // Yana taranmis
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 6 * s, 80 * s, 30 * s), Radius.circular(14 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 36 * s, 4 * s, 78 * s, 30 * s), Radius.circular(14 * s)), paint);
          // Side sweep
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 20 * s, 10 * s, 24 * s, 22 * s), Radius.circular(10 * s)), paint);
          break;
        case 4: // Dugme (buzz)
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 34 * s, 12 * s, 68 * s, 20 * s), Radius.circular(10 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 32 * s, 10 * s, 64 * s, 20 * s), Radius.circular(10 * s)), paint);
          break;
      }
    } else {
      switch (style) {
        case 0: // Uzun
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 6 * s, 80 * s, 34 * s), Radius.circular(16 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 4 * s, 76 * s, 34 * s), Radius.circular(16 * s)), paint);
          // Long sides
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 42 * s, 20 * s, 16 * s, 60 * s), Radius.circular(8 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 26 * s, 20 * s, 16 * s, 60 * s), Radius.circular(8 * s)), paint);
          break;
        case 1: // Bob
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 4 * s, 80 * s, 36 * s), Radius.circular(18 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 2 * s, 76 * s, 36 * s), Radius.circular(18 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 42 * s, 20 * s, 16 * s, 40 * s), Radius.circular(8 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 26 * s, 20 * s, 16 * s, 40 * s), Radius.circular(8 * s)), paint);
          break;
        case 2: // At kuyrugu
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 6 * s, 76 * s, 30 * s), Radius.circular(14 * s)), paint);
          // ponytail
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 20 * s, 14 * s, 14 * s, 50 * s), Radius.circular(7 * s)), paint);
          canvas.drawCircle(Offset(cx + 27 * s, 14 * s), 7 * s, paint);
          break;
        case 3: // Topuz
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 8 * s, 76 * s, 28 * s), Radius.circular(14 * s)), paint);
          canvas.drawCircle(Offset(cx, 2 * s), 16 * s, paintDark);
          canvas.drawCircle(Offset(cx, 0 * s), 16 * s, paint);
          break;
        case 4: // Dalgali
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 42 * s, 2 * s, 84 * s, 38 * s), Radius.circular(18 * s)), paint);
          for (int i = -2; i <= 2; i++) {
            canvas.drawCircle(Offset(cx + i * 10 * s, 6 * s), 10 * s, paint);
          }
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 44 * s, 20 * s, 16 * s, 56 * s), Radius.circular(8 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 28 * s, 20 * s, 16 * s, 56 * s), Radius.circular(8 * s)), paint);
          break;
      }
    }
  }

  void _drawEyes(Canvas canvas, double cx, double s) {
    final style = av.eyeStyle.clamp(0, 4);
    final eyeWhite = Paint()..color = Colors.white;
    final eyeBlack = Paint()..color = const Color(0xFF2C1810);
    final lx = cx - 14 * s;
    final rx = cx + 14 * s;
    final ey = 44 * s;

    switch (style) {
      case 0: // Normal
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 14 * s, height: 14 * s), eyeWhite);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 14 * s, height: 14 * s), eyeWhite);
        canvas.drawCircle(Offset(lx + 1 * s, ey), 5 * s, eyeBlack);
        canvas.drawCircle(Offset(rx + 1 * s, ey), 5 * s, eyeBlack);
        // Highlights
        canvas.drawCircle(Offset(lx + 3 * s, ey - 2 * s), 2 * s, eyeWhite);
        canvas.drawCircle(Offset(rx + 3 * s, ey - 2 * s), 2 * s, eyeWhite);
        break;
      case 1: // Gozluk
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 14 * s, height: 14 * s), eyeWhite);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 14 * s, height: 14 * s), eyeWhite);
        canvas.drawCircle(Offset(lx + 1 * s, ey), 5 * s, eyeBlack);
        canvas.drawCircle(Offset(rx + 1 * s, ey), 5 * s, eyeBlack);
        canvas.drawCircle(Offset(lx + 3 * s, ey - 2 * s), 2 * s, eyeWhite);
        canvas.drawCircle(Offset(rx + 3 * s, ey - 2 * s), 2 * s, eyeWhite);
        // Glasses frame
        final glassPaint = Paint()..color = const Color(0xFF3A3A3A)..style = PaintingStyle.stroke..strokeWidth = 2.5 * s;
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 20 * s, height: 18 * s), glassPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 20 * s, height: 18 * s), glassPaint);
        canvas.drawLine(Offset(lx + 10 * s, ey), Offset(rx - 10 * s, ey), glassPaint);
        break;
      case 2: // Gunes gozlugu
        final lensPaint = Paint()..color = const Color(0xFF1A1A2E).withAlpha(200);
        final framePaint = Paint()..color = const Color(0xFF2A2A2A)..style = PaintingStyle.stroke..strokeWidth = 2.5 * s;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx, ey), width: 22 * s, height: 16 * s), Radius.circular(4 * s)), lensPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(rx, ey), width: 22 * s, height: 16 * s), Radius.circular(4 * s)), lensPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx, ey), width: 22 * s, height: 16 * s), Radius.circular(4 * s)), framePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(rx, ey), width: 22 * s, height: 16 * s), Radius.circular(4 * s)), framePaint);
        canvas.drawLine(Offset(lx + 11 * s, ey), Offset(rx - 11 * s, ey), framePaint);
        break;
      case 3: // Kucuk
        canvas.drawCircle(Offset(lx, ey), 5 * s, eyeBlack);
        canvas.drawCircle(Offset(rx, ey), 5 * s, eyeBlack);
        canvas.drawCircle(Offset(lx + 1.5 * s, ey - 1 * s), 1.5 * s, eyeWhite);
        canvas.drawCircle(Offset(rx + 1.5 * s, ey - 1 * s), 1.5 * s, eyeWhite);
        break;
      case 4: // Buyuk
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 18 * s, height: 18 * s), eyeWhite);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 18 * s, height: 18 * s), eyeWhite);
        canvas.drawCircle(Offset(lx + 1 * s, ey + 1 * s), 6 * s, eyeBlack);
        canvas.drawCircle(Offset(rx + 1 * s, ey + 1 * s), 6 * s, eyeBlack);
        canvas.drawCircle(Offset(lx + 3 * s, ey - 2 * s), 2.5 * s, eyeWhite);
        canvas.drawCircle(Offset(rx + 3 * s, ey - 2 * s), 2.5 * s, eyeWhite);
        break;
    }
  }

  void _drawMouth(Canvas canvas, double cx, double s) {
    final style = av.mouthStyle.clamp(0, 4);
    final my = 64 * s;
    final mouthColor = const Color(0xFFD4625E);

    switch (style) {
      case 0: // Gulumseme
        final path = Path()
          ..moveTo(cx - 8 * s, my)
          ..quadraticBezierTo(cx, my + 8 * s, cx + 8 * s, my);
        canvas.drawPath(path, Paint()..color = mouthColor..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
        break;
      case 1: // Duz
        canvas.drawLine(Offset(cx - 6 * s, my + 2 * s), Offset(cx + 6 * s, my + 2 * s), Paint()..color = mouthColor..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
        break;
      case 2: // Acik agiz
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 2 * s), width: 14 * s, height: 10 * s), Paint()..color = mouthColor);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 4 * s), width: 10 * s, height: 5 * s), Paint()..color = const Color(0xFF8B2252));
        break;
      case 3: // Kucuk
        final path = Path()
          ..moveTo(cx - 4 * s, my + 1 * s)
          ..quadraticBezierTo(cx, my + 5 * s, cx + 4 * s, my + 1 * s);
        canvas.drawPath(path, Paint()..color = mouthColor..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
        break;
      case 4: // Genis
        final path = Path()
          ..moveTo(cx - 12 * s, my)
          ..quadraticBezierTo(cx, my + 10 * s, cx + 12 * s, my);
        canvas.drawPath(path, Paint()..color = mouthColor..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
        // Teeth
        canvas.drawRect(Rect.fromLTWH(cx - 6 * s, my, 12 * s, 4 * s), Paint()..color = Colors.white);
        break;
    }
  }

  void _drawOutfit(Canvas canvas, double cx, double s, Color color, Color dark) {
    final style = av.outfit.clamp(0, 3);
    final bodyY = 92 * s;
    final paint = Paint()..color = color;
    final paintDark = Paint()..color = dark;

    // Body shape
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bodyY + 26 * s), width: 80 * s, height: 56 * s),
      Radius.circular(16 * s),
    ), paintDark);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bodyY + 24 * s), width: 80 * s, height: 56 * s),
      Radius.circular(16 * s),
    ), paint);

    // Shoulders
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bodyY + 4 * s), width: 74 * s, height: 20 * s),
      Radius.circular(10 * s),
    ), paint);

    switch (style) {
      case 0: // T-shirt — collar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 6 * s), width: 24 * s, height: 10 * s),
          Radius.circular(5 * s),
        ), paint);
        break;
      case 1: // Gomlek — collar + buttons
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 4 * s), width: 28 * s, height: 12 * s),
          Radius.circular(6 * s),
        ), paint);
        // Collar flaps
        final collarPaint = Paint()..color = Colors.white.withAlpha(80);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 14 * s, bodyY - 8 * s, 12 * s, 10 * s), Radius.circular(4 * s)), collarPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, bodyY - 8 * s, 12 * s, 10 * s), Radius.circular(4 * s)), collarPaint);
        // Buttons
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(cx, bodyY + 8 * s + i * 10 * s), 2 * s, Paint()..color = Colors.white.withAlpha(120));
        }
        break;
      case 2: // Hoodie — hood + pocket
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 4 * s), width: 26 * s, height: 14 * s),
          Radius.circular(7 * s),
        ), paintDark);
        // Hood
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 10 * s), width: 40 * s, height: 16 * s),
          Radius.circular(8 * s),
        ), paint);
        // Pocket
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY + 30 * s), width: 36 * s, height: 14 * s),
          Radius.circular(6 * s),
        ), paintDark);
        break;
      case 3: // Kazak — ribbed bottom
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 4 * s), width: 30 * s, height: 12 * s),
          Radius.circular(6 * s),
        ), paint);
        // Ribbed texture lines
        final ribPaint = Paint()..color = dark.withAlpha(40)..strokeWidth = 1.5 * s;
        for (int i = 0; i < 4; i++) {
          final y = bodyY + 34 * s + i * 4 * s;
          canvas.drawLine(Offset(cx - 36 * s, y), Offset(cx + 36 * s, y), ribPaint);
        }
        break;
    }
  }

  void _drawAccessory(Canvas canvas, double cx, double s, Color hairColor) {
    final acc = av.accessory;
    if (acc <= 0) return;

    switch (acc) {
      case 1: // Sapka
        final paint = Paint()..color = const Color(0xFF3A3A5A);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 4 * s, 80 * s, 20 * s), Radius.circular(10 * s)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 48 * s, 18 * s, 96 * s, 8 * s), Radius.circular(4 * s)), paint);
        break;
      case 2: // Bere
        final paint = Paint()..color = const Color(0xFFCC4444);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 0 * s, 76 * s, 24 * s), Radius.circular(12 * s)), paint);
        canvas.drawCircle(Offset(cx, -2 * s), 6 * s, paint);
        break;
      case 3: // Kurdele
        final paint = Paint()..color = const Color(0xFFFF6B9D);
        canvas.drawCircle(Offset(cx + 24 * s, 12 * s), 8 * s, paint);
        // Bow loops
        final path1 = Path()..moveTo(cx + 24 * s, 12 * s)..quadraticBezierTo(cx + 38 * s, 4 * s, cx + 32 * s, 14 * s);
        final path2 = Path()..moveTo(cx + 24 * s, 12 * s)..quadraticBezierTo(cx + 16 * s, 4 * s, cx + 20 * s, 14 * s);
        canvas.drawPath(path1, Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
        canvas.drawPath(path2, Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
        break;
      case 4: // Kulaklik
        final paint = Paint()..color = const Color(0xFF3A3A3A)..style = PaintingStyle.stroke..strokeWidth = 3 * s;
        final arcRect = Rect.fromCenter(center: Offset(cx, 20 * s), width: 76 * s, height: 40 * s);
        canvas.drawArc(arcRect, pi, pi, false, paint);
        // Ear cups
        final cupPaint = Paint()..color = const Color(0xFF3A3A3A);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 38 * s, 40 * s), width: 14 * s, height: 18 * s), Radius.circular(4 * s)), cupPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 38 * s, 40 * s), width: 14 * s, height: 18 * s), Radius.circular(4 * s)), cupPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => true;
}
