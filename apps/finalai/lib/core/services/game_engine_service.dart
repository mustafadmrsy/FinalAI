/// Game Engine Service
/// Oyun mekaniklerini hesaplayan (XP, Energy, Combo, Streak)
/// 
/// Sorumluluklar:
/// - XP hesaplaması (base + combo bonus)
/// - Energy tüketimi ve günlük reset
/// - Combo takibi (üst üste tamamlanan dersler)
/// - Streak hesaplaması (gün gün çalışma)

class GameEngineService {
  /// XP ödülleri
  static const int baseXpPerLesson = 15;
  static const int perfectBonus = 10;
  static const int comboMultiplier = 2; // 2x XP combo'daysanız
  static const int comboThreshold = 3; // 3 ders = combo başlat

  /// ── Level sistemi ───────────────────────────────────────
  /// Seviye 1-5:   100 XP / seviye  (hızlı başlangıç)
  /// Seviye 6-10:  200 XP / seviye
  /// Seviye 11-20: 300 XP / seviye
  /// Seviye 21+:   500 XP / seviye
  static int xpForLevel(int level) {
    if (level <= 5) return 100;
    if (level <= 10) return 200;
    if (level <= 20) return 300;
    return 500;
  }

  /// Toplam XP'den seviye hesapla
  static int levelFromXp(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return level;
  }

  /// Mevcut seviyedeki ilerleme XP'si
  static int xpInCurrentLevel(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return remaining;
  }

  /// Mevcut seviyede gereken toplam XP
  static int xpRequiredForCurrentLevel(int totalXp) {
    return xpForLevel(levelFromXp(totalXp));
  }

  /// XP sayısını kısa formatta göster (1234 → "1.2K")
  static String formatXp(int xp) {
    if (xp < 1000) return '$xp';
    if (xp < 10000) {
      final k = xp / 1000;
      return '${k.toStringAsFixed(1)}K';
    }
    if (xp < 100000) {
      final k = (xp / 1000).floor();
      return '${k}K';
    }
    final k = (xp / 1000).floor();
    return '${k}K';
  }

  /// Energy değerleri
  static const int energyMaxDefault = 30;
  static const int energyPerLesson = 1;
  static const int energyRechargeMinutes = 30;

  /// Ders tamamlandığında XP hesapla (combo'ya göre)
  /// 
  /// Örnekler:
  /// - comboCount=0: 10 XP
  /// - comboCount=3: 20 XP (2x bonus)
  /// - comboCount=5: 20 XP (cap at 2x)
  static int calculateXpReward({required int comboCount}) {
    final multiplier = comboCount >= comboThreshold ? comboMultiplier : 1;
    return (baseXpPerLesson * multiplier).toInt();
  }

  /// Energy'nin doldurulması ne kadar sürecek?
  /// Örn: energy=20/30 → 10 dakika kaldı
  static int minutesUntilFullEnergy({
    required int currentEnergy,
    required int maxEnergy,
  }) {
    if (currentEnergy >= maxEnergy) return 0;
    final deficit = maxEnergy - currentEnergy;
    return deficit * energyRechargeMinutes;
  }

  /// Streak güncelleme
  /// - son aktivite bugün ise: streak+1
  /// - son aktivite dün ise: streak devam
  /// - son aktivite 2+ gün önce ise: streak=1 (sıfırla)
  static int calculateNewStreak({
    required DateTime? lastActiveDate,
    required int currentStreak,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastActiveDate == null) {
      return 1;
    }

    final lastActive = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
    final daysDiff = today.difference(lastActive).inDays;

    if (daysDiff == 0) {
      // Aynı gün → streak değişmez
      return currentStreak;
    } else if (daysDiff == 1) {
      // Dün aktivite var → streak devam et ve arttır
      return currentStreak + 1;
    } else {
      // 2+ gün hiçbir aktivite yok → streak sıfırla
      return 1;
    }
  }

  /// Günlük reset kontrol
  /// Energy ve xp_today'i reset etmeli mi?
  static bool shouldResetDaily({required DateTime? lastResetDate}) {
    if (lastResetDate == null) return true;

    final now = DateTime.now();
    final lastReset = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);
    final today = DateTime(now.year, now.month, now.day);

    return lastReset.isBefore(today);
  }

  /// Premium kullanıcıya energy bonus
  static int getEnergyMax({required bool isPremium}) {
    return isPremium ? energyMaxDefault * 2 : energyMaxDefault; // 60 vs 30
  }
}
