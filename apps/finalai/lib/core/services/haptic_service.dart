import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
//  HAPTIC SERVICE — Titresim geri bildirimi yonetimi
//  Acik/kapali ayari SharedPreferences ile saklanir
// ═══════════════════════════════════════════════════════════════

const _hapticKey = 'haptic_enabled';

final hapticEnabledProvider = StateNotifierProvider<HapticNotifier, bool>((ref) {
  return HapticNotifier();
});

class HapticNotifier extends StateNotifier<bool> {
  HapticNotifier() : super(true) { _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_hapticKey) ?? true;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticKey, state);
    } catch (_) {}
  }

  Future<void> setEnabled(bool v) async {
    state = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticKey, v);
    } catch (_) {}
  }
}

/// Global haptic helper — sadece ayar aciksa titresir
class Haptic {
  Haptic._();

  static bool _enabled = true;

  static void init(bool enabled) => _enabled = enabled;

  /// Hafif tik — buton tiklama
  static void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Orta tik — secim degisikligi
  static void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Sert tik — onemli eylem
  static void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Secim geri bildirimi
  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Vibrasyon — hata veya uyari
  static void vibrate() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }
}
