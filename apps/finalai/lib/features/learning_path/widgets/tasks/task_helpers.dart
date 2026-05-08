import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL GAME DESIGN SYSTEM — Duolingo-inspired flat 3D
// ═══════════════════════════════════════════════════════════════

/// Solid-shadow "pixel" decoration factory
class PxDecor {
  PxDecor._();

  // ── Palette ───────────────────────────────────────────
  static const border     = Color(0xFFE5E5E5);
  static const borderDark = Color(0xFFD0D0D0);
  static const green      = Color(0xFF58CC02);
  static const greenDark  = Color(0xFF46A302);
  static const greenBg    = Color(0xFFD7FFB8);
  static const red        = Color(0xFFFF4B4B);
  static const redDark    = Color(0xFFE53535);
  static const redBg      = Color(0xFFFFE0E0);
  static const blue       = Color(0xFF1CB0F6);
  static const blueDark   = Color(0xFF0D8BD4);
  static const blueBg     = Color(0xFFDDF4FF);
  static const gold       = Color(0xFFFFC800);
  static const goldDark   = Color(0xFFE5B400);
  static const goldBg     = Color(0xFFFFF4CC);
  static const purple     = Color(0xFFCE82FF);
  static const purpleDark = Color(0xFFB06FE0);
  static const teal       = Color(0xFF0ABFBC);
  static const tealDark   = Color(0xFF078F8D);
  static const tealBg     = Color(0xFFD0F5F4);
  static const orange     = Color(0xFFFF9600);
  static const orangeDark = Color(0xFFE07800);
  static const orangeBg   = Color(0xFFFFF3E0);

  /// Standard card — white with solid bottom shadow
  static BoxDecoration card({Color? bg, Color? borderColor, double depth = 4}) {
    final c = borderColor ?? border;
    return BoxDecoration(
      color: bg ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c, width: 2),
      boxShadow: [BoxShadow(color: c, offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  /// Active/selected card
  static BoxDecoration selected({Color color = blue, double depth = 4}) {
    return BoxDecoration(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color, width: 2.5),
      boxShadow: [BoxShadow(color: color.withAlpha(100), offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  /// Correct answer card
  static BoxDecoration correct({double depth = 4}) {
    return BoxDecoration(
      color: greenBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: green, width: 2.5),
      boxShadow: [BoxShadow(color: greenDark.withAlpha(80), offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  /// Wrong answer card
  static BoxDecoration wrong({double depth = 4}) {
    return BoxDecoration(
      color: redBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: red, width: 2.5),
      boxShadow: [BoxShadow(color: redDark.withAlpha(80), offset: Offset(0, depth), blurRadius: 0)],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  THEME-AWARE PIXEL HELPER  —  Px.of(context)
// ═══════════════════════════════════════════════════════════════
class Px {
  Px._(this.isDark);
  final bool isDark;

  factory Px.of(BuildContext context) =>
      Px._(Theme.of(context).brightness == Brightness.dark);

  // ── Backgrounds ────────────────────────────────────
  Color get bg        => isDark ? const Color(0xFF0F1923) : const Color(0xFFF7F5F0);
  Color get card      => isDark ? const Color(0xFF1A2836) : Colors.white;
  Color get surface   => isDark ? const Color(0xFF22313F) : const Color(0xFFF5F5F5);

  // ── Borders / Shadows ──────────────────────────────
  Color get border    => isDark ? const Color(0xFF2A3D4E) : PxDecor.border;
  Color get borderDk  => isDark ? const Color(0xFF1E2F3E) : PxDecor.borderDark;
  Color get shadow    => isDark ? const Color(0xFF0A1018) : PxDecor.border;

  // ── Text ───────────────────────────────────────────
  Color get text      => isDark ? const Color(0xFFE8EDF2) : Colors.black87;
  Color get textSub   => isDark ? const Color(0xFF8FA0B0) : const Color(0xFF757575);
  Color get textMuted => isDark ? const Color(0xFF5A7080) : const Color(0xFF9E9E9E);

  // ── Accent background tones (for cards with accent) ──
  Color accentBg(Color c) => isDark ? c.withAlpha(25) : c.withAlpha(15);

  // ── Decorations ────────────────────────────────────
  BoxDecoration cardDeco({Color? bg, Color? borderColor, double depth = 4}) {
    final c = borderColor ?? border;
    return BoxDecoration(
      color: bg ?? card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c, width: 2),
      boxShadow: [BoxShadow(color: isDark ? shadow : c, offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  BoxDecoration heroDeco(Color color, Color dark, {double depth = 5}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: dark, width: 2),
      boxShadow: [BoxShadow(color: dark, offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  BoxDecoration selectedDeco({Color color = PxDecor.blue, double depth = 4}) {
    return BoxDecoration(
      color: accentBg(color),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color, width: 2.5),
      boxShadow: [BoxShadow(color: color.withAlpha(isDark ? 40 : 100), offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  BoxDecoration correctDeco({double depth = 4}) {
    return BoxDecoration(
      color: isDark ? PxDecor.green.withAlpha(30) : PxDecor.greenBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PxDecor.green, width: 2.5),
      boxShadow: [BoxShadow(color: PxDecor.greenDark.withAlpha(isDark ? 50 : 80), offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  BoxDecoration wrongDeco({double depth = 4}) {
    return BoxDecoration(
      color: isDark ? PxDecor.red.withAlpha(30) : PxDecor.redBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PxDecor.red, width: 2.5),
      boxShadow: [BoxShadow(color: PxDecor.redDark.withAlpha(isDark ? 50 : 80), offset: Offset(0, depth), blurRadius: 0)],
    );
  }

  BoxDecoration sectionDeco() {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 2),
      boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0)],
    );
  }
}

/// Tum ekranlarda tutarli ikon ve renk sabitleri
class PxIcons {
  PxIcons._();
  // XP = parlak zumrut yesili yildiz
  static const xpIcon  = Icons.star_rounded;
  static const xpColor = Color(0xFF00C853);
  static const xpDark  = Color(0xFF00A844);
  // Enerji = pil ikonu (renk enerji yuzdesine gore degisir)
  static const energyIcon  = Icons.battery_full_rounded;
  static const energyColor = PxDecor.green;
  static const energyDark  = PxDecor.greenDark;

  /// Enerji yuzdesine gore pil rengi: >60% yesil, >25% sari, <=25% kirmizi
  static Color energyColorByPct(double pct) {
    if (pct > 0.6) return PxDecor.green;
    if (pct > 0.25) return PxDecor.gold;
    return PxDecor.red;
  }

  static Color energyDarkByPct(double pct) {
    if (pct > 0.6) return PxDecor.greenDark;
    if (pct > 0.25) return PxDecor.goldDark;
    return PxDecor.redDark;
  }

  static IconData energyIconByPct(double pct) {
    if (pct > 0.6) return Icons.battery_full_rounded;
    if (pct > 0.25) return Icons.battery_3_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }
  // Seri = turuncu alev
  static const streakIcon  = Icons.local_fire_department_rounded;
  static const streakColor = PxDecor.orange;
  static const streakDark  = PxDecor.orangeDark;
}

/// Task type metadata
class TaskMeta {
  const TaskMeta({required this.label, required this.icon, required this.color, required this.darkColor});
  final String label;
  final IconData icon;
  final Color color;
  final Color darkColor;

  List<Color> get gradient => [color, darkColor];

  static TaskMeta fromType(String type) {
    switch (type) {
      case 'matching':
        return const TaskMeta(label: 'Eslestir', icon: Icons.compare_arrows_rounded, color: PxDecor.teal, darkColor: PxDecor.tealDark);
      case 'order_steps':
        return const TaskMeta(label: 'Sirala', icon: Icons.sort_rounded, color: PxDecor.blue, darkColor: PxDecor.blueDark);
      case 'fill_blank':
        return const TaskMeta(label: 'Bosluk Doldur', icon: Icons.text_fields_rounded, color: PxDecor.purple, darkColor: PxDecor.purpleDark);
      case 'tap_select':
        return const TaskMeta(label: 'Dogruyu Sec', icon: Icons.touch_app_rounded, color: PxDecor.green, darkColor: PxDecor.greenDark);
      case 'spot_error':
        return const TaskMeta(label: 'Hatayi Bul', icon: Icons.find_replace_rounded, color: PxDecor.gold, darkColor: PxDecor.goldDark);
      case 'image_select':
        return const TaskMeta(label: 'Resim Sec', icon: Icons.image_search_rounded, color: PxDecor.orange, darkColor: PxDecor.orangeDark);
      case 'translate_sentence':
        return const TaskMeta(label: 'Cevir', icon: Icons.translate_rounded, color: PxDecor.blue, darkColor: PxDecor.blueDark);
      case 'speak_word':
        return const TaskMeta(label: 'Soyle', icon: Icons.mic_rounded, color: PxDecor.purple, darkColor: PxDecor.purpleDark);
      default:
        return const TaskMeta(label: 'Gorev', icon: Icons.task_alt_rounded, color: PxDecor.teal, darkColor: PxDecor.tealDark);
    }
  }
}
