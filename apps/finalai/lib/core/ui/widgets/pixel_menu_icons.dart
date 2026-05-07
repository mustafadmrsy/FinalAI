import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL MENU ICONS — 2D game art icons for profile dropdown menu
//  Same style as PixelNavIcons but for menu items
// ═══════════════════════════════════════════════════════════════

class PixelMenuIcons {
  PixelMenuIcons._();

  /// Profilim — pixel art kisi ikonu
  static Widget profile({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0ABFBC),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFF088F8D), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF088F8D).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Stack(children: [
        // Kafa
        Positioned(
          left: size * 0.3, top: size * 0.12,
          child: Container(
            width: size * 0.4, height: size * 0.36,
            decoration: BoxDecoration(color: const Color(0xFFFFDCB5), borderRadius: BorderRadius.circular(size * 0.15)),
          ),
        ),
        // Gozler
        Positioned(left: size * 0.34, top: size * 0.24, child: Container(width: size * 0.08, height: size * 0.08, decoration: const BoxDecoration(color: Color(0xFF2C1810), shape: BoxShape.circle))),
        Positioned(left: size * 0.58, top: size * 0.24, child: Container(width: size * 0.08, height: size * 0.08, decoration: const BoxDecoration(color: Color(0xFF2C1810), shape: BoxShape.circle))),
        // Govde
        Positioned(
          left: size * 0.2, bottom: size * 0.06,
          child: Container(
            width: size * 0.6, height: size * 0.3,
            decoration: BoxDecoration(color: Colors.white.withAlpha(180), borderRadius: BorderRadius.circular(size * 0.1)),
          ),
        ),
      ]),
    );
  }

  /// Istatistik — pixel grafik cubuklar
  static Widget stats({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1CB0F6),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFF0D7AB5), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF0D7AB5).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _bar(size, 0.35, const Color(0xFF58CC02)),
          _bar(size, 0.55, Colors.white),
          _bar(size, 0.45, const Color(0xFFFFC800)),
          _bar(size, 0.7, const Color(0xFFFF4B4B)),
        ]),
      ),
    );
  }

  /// Quiz — pixel soru isareti
  static Widget quiz({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9600),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFCC7800), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFCC7800).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Center(child: Stack(children: [
        // Yildiz arka plan
        Positioned.fill(child: Center(child: Icon(Icons.auto_awesome_rounded, size: size * 0.3, color: Colors.white.withAlpha(60)))),
        // Simşek
        Center(child: Icon(Icons.quiz_rounded, size: size * 0.45, color: Colors.white)),
      ])),
    );
  }

  /// Basarimlar — pixel kupa
  static Widget achievements({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC800),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFCC9E00), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFCC9E00).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Stack(children: [
        // Kupa govde
        Center(child: Container(
          width: size * 0.42, height: size * 0.38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(size * 0.14), top: Radius.circular(size * 0.06)),
          ),
        )),
        // Yildiz
        Positioned(
          right: size * 0.18, top: size * 0.12,
          child: Icon(Icons.star_rounded, size: size * 0.2, color: Colors.white.withAlpha(180)),
        ),
        // Taban
        Positioned(
          left: size * 0.3, bottom: size * 0.14,
          child: Container(
            width: size * 0.4, height: size * 0.08,
            decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ]),
    );
  }

  /// Premium — pixel elmas
  static Widget premium({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFCE82FF),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFF9B56D4), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF9B56D4).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Center(child: Stack(children: [
        // Isiltil
        Positioned(left: size * 0.18, top: size * 0.2, child: Container(width: size * 0.08, height: size * 0.08, decoration: BoxDecoration(color: Colors.white.withAlpha(120), shape: BoxShape.circle))),
        Center(child: Icon(Icons.diamond_rounded, size: size * 0.48, color: Colors.white)),
      ])),
    );
  }

  /// Bildirimler — pixel zil
  static Widget notifications({double size = 38, int unreadCount = 0}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF58CC02),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFF3A8202), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF3A8202).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Stack(children: [
        Center(child: Icon(Icons.notifications_rounded, size: size * 0.48, color: Colors.white)),
        if (unreadCount > 0) Positioned(
          right: size * 0.12, top: size * 0.1,
          child: Container(
            width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.14),
            )),
          ),
        ),
      ]),
    );
  }

  /// Cikis — pixel kapi
  static Widget signout({double size = 38}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4B4B),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFCC2222), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFCC2222).withAlpha(80), offset: const Offset(0, 2.5), blurRadius: 0)],
      ),
      child: Center(child: Icon(Icons.logout_rounded, size: size * 0.45, color: Colors.white)),
    );
  }

  static Widget _bar(double parentSize, double heightPct, Color color) {
    return Container(
      width: parentSize * 0.1,
      height: parentSize * 0.6 * heightPct,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
