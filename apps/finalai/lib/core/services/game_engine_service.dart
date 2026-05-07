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
  static const int baseXpPerLesson = 10;
  static const int comboMultiplier = 2; // 2x XP combo'daysanız
  static const int comboThreshold = 3; // 3 ders = combo başlat

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
