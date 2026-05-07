import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  AVATAR PARTS — Colors and style catalogs for avatar customization
// ═══════════════════════════════════════════════════════════════

class AvatarParts {
  AvatarParts._();

  // ── Skin tones ──────────────────────────────
  static const skinTones = [
    Color(0xFFFFDCB5), // light
    Color(0xFFF5C9A0), // fair
    Color(0xFFE8B07A), // medium
    Color(0xFFD49A6A), // tan
    Color(0xFFAA7744), // brown
    Color(0xFF8B5E3C), // dark brown
  ];

  // ── Hair colors ─────────────────────────────
  static const hairColors = [
    Color(0xFF2C1810), // black
    Color(0xFF5A3825), // dark brown
    Color(0xFF8B6914), // brown
    Color(0xFFD4A537), // blonde
    Color(0xFFC04030), // red
    Color(0xFF6B4C9A), // purple
    Color(0xFF2E86AB), // blue
    Color(0xFF58CC02), // green
  ];

  // ── Outfit colors ───────────────────────────
  static const outfitColors = [
    Color(0xFF58CC02), // green
    Color(0xFF1CB0F6), // blue
    Color(0xFFFF4B4B), // red
    Color(0xFFFFC800), // yellow
    Color(0xFFCE82FF), // purple
    Color(0xFFFF9600), // orange
    Color(0xFF0ABFBC), // teal
    Color(0xFFFF6B9D), // pink
  ];

  // ── Hair style labels ───────────────────────
  static const hairStylesMale = ['Kisa', 'Dalgali', 'Yukari', 'Yana Taranmis', 'Dugme'];
  static const hairStylesFemale = ['Uzun', 'Bob', 'At Kuyrugu', 'Topuz', 'Dalgali'];

  // ── Eye style labels ────────────────────────
  static const eyeStyles = ['Normal', 'Gozluk', 'Gunes Gozlugu', 'Kucuk', 'Buyuk'];

  // ── Mouth styles ────────────────────────────
  static const mouthStyles = ['Gulumseme', 'Duz', 'Acik Agiz', 'Kucuk', 'Genis'];

  // ── Accessories ─────────────────────────────
  static const accessories = ['Yok', 'Sapka', 'Bere', 'Kurdele', 'Kulaklik'];

  // ── Outfit labels ───────────────────────────
  static const outfits = ['T-Shirt', 'Gomlek', 'Hoodie', 'Kazak'];
}
