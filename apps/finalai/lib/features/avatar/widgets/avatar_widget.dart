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

    // ── Eyebrows ──
    _drawEyebrows(canvas, cx, s);

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
    final style = av.hairStyle.clamp(0, 7);

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
        case 5: // Uzun (erkek)
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 4 * s, 80 * s, 36 * s), Radius.circular(16 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 2 * s, 76 * s, 36 * s), Radius.circular(16 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 42 * s, 24 * s, 14 * s, 48 * s), Radius.circular(7 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 28 * s, 24 * s, 14 * s, 48 * s), Radius.circular(7 * s)), paint);
          break;
        case 6: // Afro
          canvas.drawCircle(Offset(cx, 20 * s), 42 * s, paintDark);
          canvas.drawCircle(Offset(cx, 18 * s), 42 * s, paint);
          break;
        case 7: // Mohawk
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 10 * s, -8 * s, 20 * s, 34 * s), Radius.circular(6 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8 * s, -10 * s, 16 * s, 34 * s), Radius.circular(6 * s)), paint);
          // Fade sides
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 34 * s, 16 * s, 68 * s, 12 * s), Radius.circular(6 * s)), Paint()..color = color.withAlpha(80));
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
        case 5: // Pixie
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 4 * s, 76 * s, 28 * s), Radius.circular(14 * s)), paintDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 36 * s, 2 * s, 72 * s, 28 * s), Radius.circular(14 * s)), paint);
          // Side sweep
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 18 * s, 8 * s, 20 * s, 18 * s), Radius.circular(8 * s)), paint);
          break;
        case 6: // Orgu
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 40 * s, 4 * s, 80 * s, 32 * s), Radius.circular(16 * s)), paint);
          // Two braids
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 30 * s, 28 * s, 10 * s, 55 * s), Radius.circular(5 * s)), paint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 20 * s, 28 * s, 10 * s, 55 * s), Radius.circular(5 * s)), paint);
          // Braid ties
          canvas.drawCircle(Offset(cx - 25 * s, 82 * s), 4 * s, Paint()..color = const Color(0xFFFF6B9D));
          canvas.drawCircle(Offset(cx + 25 * s, 82 * s), 4 * s, Paint()..color = const Color(0xFFFF6B9D));
          break;
        case 7: // Kabarik (Curly big)
          canvas.drawCircle(Offset(cx, 16 * s), 42 * s, paintDark);
          canvas.drawCircle(Offset(cx, 14 * s), 42 * s, paint);
          // Curly bumps
          for (int i = -2; i <= 2; i++) {
            canvas.drawCircle(Offset(cx + i * 14 * s, 4 * s), 12 * s, paint);
          }
          break;
      }
    }
  }

  void _drawEyebrows(Canvas canvas, double cx, double s) {
    final style = av.eyebrowStyle.clamp(0, 5);
    final browColor = const Color(0xFF2C1810);
    final lx = cx - 14 * s;
    final rx = cx + 14 * s;
    final by = 34 * s;

    switch (style) {
      case 0: // Normal
        final p = Paint()..color = browColor..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(lx - 6 * s, by), Offset(lx + 6 * s, by), p);
        canvas.drawLine(Offset(rx - 6 * s, by), Offset(rx + 6 * s, by), p);
        break;
      case 1: // Kalin
        final p = Paint()..color = browColor..strokeWidth = 4 * s..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(lx - 7 * s, by), Offset(lx + 7 * s, by), p);
        canvas.drawLine(Offset(rx - 7 * s, by), Offset(rx + 7 * s, by), p);
        break;
      case 2: // Ince
        final p = Paint()..color = browColor..strokeWidth = 1.5 * s..strokeCap = StrokeCap.round;
        final lPath = Path()..moveTo(lx - 6 * s, by + 1 * s)..quadraticBezierTo(lx, by - 2 * s, lx + 6 * s, by + 1 * s);
        final rPath = Path()..moveTo(rx - 6 * s, by + 1 * s)..quadraticBezierTo(rx, by - 2 * s, rx + 6 * s, by + 1 * s);
        canvas.drawPath(lPath, p..style = PaintingStyle.stroke);
        canvas.drawPath(rPath, p..style = PaintingStyle.stroke);
        break;
      case 3: // Yukari (arched)
        final p = Paint()..color = browColor..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
        final lPath = Path()..moveTo(lx - 7 * s, by + 2 * s)..quadraticBezierTo(lx, by - 5 * s, lx + 7 * s, by);
        final rPath = Path()..moveTo(rx - 7 * s, by)..quadraticBezierTo(rx, by - 5 * s, rx + 7 * s, by + 2 * s);
        canvas.drawPath(lPath, p);
        canvas.drawPath(rPath, p);
        break;
      case 4: // Kizgin (angled down)
        final p = Paint()..color = browColor..strokeWidth = 3 * s..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(lx - 6 * s, by - 2 * s), Offset(lx + 6 * s, by + 2 * s), p);
        canvas.drawLine(Offset(rx - 6 * s, by + 2 * s), Offset(rx + 6 * s, by - 2 * s), p);
        break;
      case 5: // Yuvarlak
        final p = Paint()..color = browColor..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
        canvas.drawArc(Rect.fromCenter(center: Offset(lx, by + 2 * s), width: 14 * s, height: 8 * s), 3.14, 3.14, false, p);
        canvas.drawArc(Rect.fromCenter(center: Offset(rx, by + 2 * s), width: 14 * s, height: 8 * s), 3.14, 3.14, false, p);
        break;
    }
  }

  void _drawEyes(Canvas canvas, double cx, double s) {
    final style = av.eyeStyle.clamp(0, 7);
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
      case 5: // Uykulu
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 14 * s, height: 10 * s), eyeWhite);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 14 * s, height: 10 * s), eyeWhite);
        canvas.drawCircle(Offset(lx, ey + 1 * s), 4 * s, eyeBlack);
        canvas.drawCircle(Offset(rx, ey + 1 * s), 4 * s, eyeBlack);
        // Heavy eyelids
        final lidPaint = Paint()..color = const Color(0xFF2C1810).withAlpha(60)..strokeWidth = 2.5 * s..style = PaintingStyle.stroke;
        canvas.drawArc(Rect.fromCenter(center: Offset(lx, ey - 1 * s), width: 16 * s, height: 10 * s), 3.14, 3.14, false, lidPaint);
        canvas.drawArc(Rect.fromCenter(center: Offset(rx, ey - 1 * s), width: 16 * s, height: 10 * s), 3.14, 3.14, false, lidPaint);
        break;
      case 6: // Kedi Goz
        // Almond-shaped
        final leftPath = Path()
          ..moveTo(lx - 8 * s, ey)
          ..quadraticBezierTo(lx, ey - 8 * s, lx + 9 * s, ey - 3 * s)
          ..quadraticBezierTo(lx, ey + 6 * s, lx - 8 * s, ey);
        final rightPath = Path()
          ..moveTo(rx - 9 * s, ey - 3 * s)
          ..quadraticBezierTo(rx, ey - 8 * s, rx + 8 * s, ey)
          ..quadraticBezierTo(rx, ey + 6 * s, rx - 9 * s, ey - 3 * s);
        canvas.drawPath(leftPath, eyeWhite);
        canvas.drawPath(rightPath, eyeWhite);
        canvas.drawCircle(Offset(lx, ey - 1 * s), 4 * s, Paint()..color = const Color(0xFF2E8B57));
        canvas.drawCircle(Offset(rx, ey - 1 * s), 4 * s, Paint()..color = const Color(0xFF2E8B57));
        canvas.drawCircle(Offset(lx, ey - 1 * s), 2 * s, eyeBlack);
        canvas.drawCircle(Offset(rx, ey - 1 * s), 2 * s, eyeBlack);
        break;
      case 7: // Yildiz
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: 16 * s, height: 16 * s), eyeWhite);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey), width: 16 * s, height: 16 * s), eyeWhite);
        // Star pupils
        final starPaint = Paint()..color = const Color(0xFFFFC800);
        for (final ox in [lx, rx]) {
          for (int j = 0; j < 4; j++) {
            final a = j * 3.14159 / 2;
            final dx2 = cos(a) * 4 * s;
            final dy2 = sin(a) * 4 * s;
            canvas.drawLine(Offset(ox, ey), Offset(ox + dx2, ey + dy2), Paint()..color = starPaint.color..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
          }
          canvas.drawCircle(Offset(ox, ey), 2.5 * s, eyeBlack);
        }
        break;
    }
  }

  void _drawMouth(Canvas canvas, double cx, double s) {
    final style = av.mouthStyle.clamp(0, 7);
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
      case 5: // Dudak (full lips)
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 2 * s), width: 16 * s, height: 8 * s), Paint()..color = const Color(0xFFE84070));
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 4 * s), width: 12 * s, height: 5 * s), Paint()..color = const Color(0xFFCC3060));
        break;
      case 6: // Saskin (O mouth)
        canvas.drawCircle(Offset(cx, my + 3 * s), 5 * s, Paint()..color = mouthColor);
        canvas.drawCircle(Offset(cx, my + 3 * s), 3 * s, Paint()..color = const Color(0xFF8B2252));
        break;
      case 7: // Dis Gosterme
        final path7 = Path()
          ..moveTo(cx - 10 * s, my)
          ..quadraticBezierTo(cx, my + 8 * s, cx + 10 * s, my);
        canvas.drawPath(path7, Paint()..color = mouthColor..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
        // Individual teeth
        final teethPaint = Paint()..color = Colors.white;
        for (int i = -2; i <= 2; i++) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + i * 4 * s - 1.5 * s, my, 3 * s, 4 * s), Radius.circular(1 * s)), teethPaint);
        }
        break;
    }
  }

  void _drawOutfit(Canvas canvas, double cx, double s, Color color, Color dark) {
    final style = av.outfit.clamp(0, 7);
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
      case 4: // Yelek
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 4 * s), width: 24 * s, height: 10 * s),
          Radius.circular(5 * s),
        ), paint);
        // V-shape front opening
        final vestInner = Paint()..color = Colors.white.withAlpha(60);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 6 * s, bodyY + 4 * s, 12 * s, 36 * s), Radius.circular(4 * s)), vestInner);
        break;
      case 5: // Ceket
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 6 * s), width: 28 * s, height: 12 * s),
          Radius.circular(6 * s),
        ), paint);
        // Lapels
        final lapelPaint = Paint()..color = dark;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 18 * s, bodyY - 4 * s, 14 * s, 20 * s), Radius.circular(4 * s)), lapelPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, bodyY - 4 * s, 14 * s, 20 * s), Radius.circular(4 * s)), lapelPaint);
        // Center line
        canvas.drawLine(Offset(cx, bodyY + 2 * s), Offset(cx, bodyY + 44 * s), Paint()..color = dark..strokeWidth = 2 * s);
        break;
      case 6: // Elbise
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 6 * s), width: 24 * s, height: 10 * s),
          Radius.circular(5 * s),
        ), paint);
        // Flared bottom
        final dressPath = Path()
          ..moveTo(cx - 36 * s, bodyY + 16 * s)
          ..lineTo(cx - 44 * s, bodyY + 54 * s)
          ..lineTo(cx + 44 * s, bodyY + 54 * s)
          ..lineTo(cx + 36 * s, bodyY + 16 * s)
          ..close();
        canvas.drawPath(dressPath, paint);
        canvas.drawPath(dressPath, Paint()..color = dark..style = PaintingStyle.stroke..strokeWidth = 2 * s);
        break;
      case 7: // Tank Top
        // No collar, wide neck
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, bodyY - 2 * s), width: 34 * s, height: 10 * s),
          Radius.circular(5 * s),
        ), Paint()..color = Colors.white.withAlpha(0)); // invisible neck area
        // Shoulder straps
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 30 * s, bodyY - 2 * s, 12 * s, 16 * s), Radius.circular(4 * s)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 18 * s, bodyY - 2 * s, 12 * s, 16 * s), Radius.circular(4 * s)), paint);
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
        final path1 = Path()..moveTo(cx + 24 * s, 12 * s)..quadraticBezierTo(cx + 38 * s, 4 * s, cx + 32 * s, 14 * s);
        final path2 = Path()..moveTo(cx + 24 * s, 12 * s)..quadraticBezierTo(cx + 16 * s, 4 * s, cx + 20 * s, 14 * s);
        canvas.drawPath(path1, Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
        canvas.drawPath(path2, Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
        break;
      case 4: // Kulaklik
        final hpPaint = Paint()..color = const Color(0xFF3A3A3A)..style = PaintingStyle.stroke..strokeWidth = 3 * s;
        final arcRect = Rect.fromCenter(center: Offset(cx, 20 * s), width: 76 * s, height: 40 * s);
        canvas.drawArc(arcRect, pi, pi, false, hpPaint);
        final cupPaint = Paint()..color = const Color(0xFF3A3A3A);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 38 * s, 40 * s), width: 14 * s, height: 18 * s), Radius.circular(4 * s)), cupPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 38 * s, 40 * s), width: 14 * s, height: 18 * s), Radius.circular(4 * s)), cupPaint);
        break;
      case 5: // Tac
        final crownPaint = Paint()..color = const Color(0xFFFFC800);
        final crownDark = Paint()..color = const Color(0xFFE5B400);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 28 * s, 2 * s, 56 * s, 14 * s), Radius.circular(4 * s)), crownDark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 28 * s, 0, 56 * s, 14 * s), Radius.circular(4 * s)), crownPaint);
        // Crown points
        for (int i = -2; i <= 2; i++) {
          final cp = Path()..moveTo(cx + i * 12 * s - 5 * s, 4 * s)..lineTo(cx + i * 12 * s, -8 * s)..lineTo(cx + i * 12 * s + 5 * s, 4 * s)..close();
          canvas.drawPath(cp, crownPaint);
        }
        // Gems
        canvas.drawCircle(Offset(cx, 6 * s), 3 * s, Paint()..color = const Color(0xFFFF4B4B));
        canvas.drawCircle(Offset(cx - 14 * s, 6 * s), 2 * s, Paint()..color = const Color(0xFF1CB0F6));
        canvas.drawCircle(Offset(cx + 14 * s, 6 * s), 2 * s, Paint()..color = const Color(0xFF58CC02));
        break;
      case 6: // Bandana
        final bandPaint = Paint()..color = const Color(0xFFFF4B4B);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 12 * s, 76 * s, 10 * s), Radius.circular(3 * s)), bandPaint);
        // Knot on side
        canvas.drawCircle(Offset(cx + 36 * s, 18 * s), 6 * s, bandPaint);
        // Trailing ends
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 34 * s, 22 * s, 6 * s, 16 * s), Radius.circular(3 * s)), bandPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 40 * s, 20 * s, 5 * s, 14 * s), Radius.circular(3 * s)), bandPaint);
        break;
      case 7: // Gunes Vizoru
        final visorPaint = Paint()..color = const Color(0xFF1CB0F6);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 38 * s, 10 * s, 76 * s, 8 * s), Radius.circular(4 * s)), visorPaint);
        // Visor brim
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 44 * s, 16 * s, 88 * s, 6 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF0D8BD4));
        break;
      case 8: // Boncuk Kolye
        final necklacePaint = Paint()..color = const Color(0xFFFFC800)..style = PaintingStyle.stroke..strokeWidth = 2 * s;
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, 80 * s), width: 40 * s, height: 20 * s), 0, pi, false, necklacePaint);
        // Beads
        for (int i = -3; i <= 3; i++) {
          final bx = cx + i * 6 * s;
          final by = 80 * s + (10 - (i.abs() * 2)) * s;
          final colors = [const Color(0xFFFF4B4B), const Color(0xFF1CB0F6), const Color(0xFF58CC02), const Color(0xFFFFC800), const Color(0xFFCE82FF)];
          canvas.drawCircle(Offset(bx, by), 2.5 * s, Paint()..color = colors[(i + 3) % colors.length]);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => true;
}
