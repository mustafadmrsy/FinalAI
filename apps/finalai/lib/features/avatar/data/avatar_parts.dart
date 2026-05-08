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
    Color(0xFF6B4226), // deep brown
    Color(0xFFFFF0DB), // porcelain
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
    Color(0xFFFF6B9D), // pink
    Color(0xFFFF9600), // orange
    Color(0xFFE0E0E0), // silver/gray
    Color(0xFF0ABFBC), // teal
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
    Color(0xFF2C1810), // black
    Color(0xFFE0E0E0), // white/gray
    Color(0xFF4A6741), // army green
    Color(0xFF8B5E3C), // brown
  ];

  // ── Hair style labels ───────────────────────
  static const hairStylesMale = ['Kisa', 'Dalgali', 'Yukari', 'Yana Taranmis', 'Dugme', 'Uzun', 'Afro', 'Mohawk'];
  static const hairStylesFemale = ['Uzun', 'Bob', 'At Kuyrugu', 'Topuz', 'Dalgali', 'Pixie', 'Orgu', 'Kabarik'];

  // ── Eyebrow style labels ───────────────────
  static const eyebrowStyles = ['Normal', 'Kalin', 'Ince', 'Yukari', 'Kizgin', 'Yuvarlak'];

  // ── Eye style labels ────────────────────────
  static const eyeStyles = ['Normal', 'Gozluk', 'Gunes Gozlugu', 'Kucuk', 'Buyuk', 'Uykulu', 'Kedi Goz', 'Yildiz'];

  // ── Mouth styles ────────────────────────────
  static const mouthStyles = ['Gulumseme', 'Duz', 'Acik Agiz', 'Kucuk', 'Genis', 'Dudak', 'Saskin', 'Dis Gosterme'];

  // ── Accessories ─────────────────────────────
  static const accessories = ['Yok', 'Sapka', 'Bere', 'Kurdele', 'Kulaklik', 'Tac', 'Bandana', 'Gunes Vizoru', 'Boncuk Kolye'];

  // ── Outfit labels ───────────────────────────
  static const outfits = ['T-Shirt', 'Gomlek', 'Hoodie', 'Kazak', 'Yelek', 'Ceket', 'Elbise', 'Tank Top'];
}
